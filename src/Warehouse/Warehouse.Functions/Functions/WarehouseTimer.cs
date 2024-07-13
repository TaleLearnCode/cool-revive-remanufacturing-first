using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Warehouse.Services;

namespace Warehouse.Functions
{
	public class WarehouseTimer(
		ILoggerFactory loggerFactory,
		IHttpClientFactory httpClientFactory,
		WarehouseServices warehouseServices)
	{

		private readonly ILogger _logger = loggerFactory.CreateLogger<WarehouseTimer>();
		private readonly HttpClient _httpClient = httpClientFactory.CreateClient();
		private readonly WarehouseServices _warehouseServices = warehouseServices;

		[Function("WarehouseTimer")]
		public async Task RunAsync([TimerTrigger("%TimerSchedule%")] TimerInfo timerInfo)
		{
			_logger.LogInformation("Warehouse Timer trigger function executed at: {dateTime}", DateTime.Now);
			await _warehouseServices.CompletePickingOrdersAsync(_httpClient, "Wally");
			await _warehouseServices.StartPickingOrdersAsync(_httpClient, "Wally");
			if (timerInfo.ScheduleStatus is not null)
				_logger.LogInformation("Warehouse Next timer schedule at: {nextTime}", timerInfo.ScheduleStatus.Next);
		}
	}
}
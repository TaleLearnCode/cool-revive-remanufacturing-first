using Conveyance.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace Conveyance.Functions;

public class ConveyanceTimer(ILoggerFactory loggerFactory, IHttpClientFactory httpClientFactory, ConveyanceServices conveyanceServices)
{

	private readonly ILogger _logger = loggerFactory.CreateLogger<ConveyanceTimer>();
	private readonly HttpClient _httpClient = httpClientFactory.CreateClient();
	private readonly ConveyanceServices _conveyanceServices = conveyanceServices;

	[Function("ConveyanceTimer")]
	public async Task RunAsync([TimerTrigger("%ConveyanceSchedule%")] TimerInfo timerInfo)
	{
		_logger.LogInformation("C# Timer trigger function executed at: {dateTime}", DateTime.Now);
		await _conveyanceServices.StartMissionsAsync(_httpClient, "Wally");
		if (timerInfo.ScheduleStatus is not null)
		{
			_logger.LogInformation("Next timer schedule at: {nextTime}", timerInfo.ScheduleStatus.Next);
		}
	}

}
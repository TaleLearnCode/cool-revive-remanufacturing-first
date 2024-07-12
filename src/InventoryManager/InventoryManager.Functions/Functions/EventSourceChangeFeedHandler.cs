using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Remanufacturing.InventoryManager.Entities;
using Remanufacturing.InventoryManager.Services;

namespace InventoryManager.Functions.Functions;

public class EventSourceChangeFeedHandler(ILoggerFactory loggerFactory, InventoryServices inventoryServices)
{

	private readonly ILogger _logger = loggerFactory.CreateLogger<EventSourceChangeFeedHandler>();
	private readonly InventoryServices _inventoryServices = inventoryServices;

	[Function("EventSourceChangeFeedHandler")]
	public async Task RunAsync([CosmosDBTrigger(
		databaseName: "%InventoryEventSourceContainerName%",
		containerName: "%EventSourceContainerName%",
		Connection = "CosmosDBConnectionString",
		LeaseContainerName = "leases",
		CreateLeaseContainerIfNotExists = true)] IReadOnlyList<InventoryEntity> input)
	{
		if (input != null && input.Count > 0)
		{
			_logger.LogInformation("Documents modified: {documentCount}", input.Count);
			await _inventoryServices.EventSourceChangeFeedHandlerAsync(input);
		}
	}

}
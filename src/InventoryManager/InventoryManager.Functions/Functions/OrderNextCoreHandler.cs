using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Remanufacturing.InventoryManager.Entities;
using Remanufacturing.InventoryManager.Extensions;

namespace InventoryManager.Functions.Functions;

public class OrderNextCoreHandler(ILogger<OrderNextCoreHandler> logger)
{
	private readonly ILogger<OrderNextCoreHandler> _logger = logger;

	[Function(nameof(OrderNextCoreHandler))]
	[CosmosDBOutput(
			databaseName: "%EventSourceDatabaseName%",
			containerName: "%EventSourceContainerName%",
			PartitionKey = "%EventSourcePartitionKey%",
			Connection = "CosmosDBConnectionString",
			CreateIfNotExists = false)]
	public async Task<InventoryEntity?> RunAsync(
		[ServiceBusTrigger("%OrderNextCore_TopicName%", "%OrderNextCoreInventoryManagement%", Connection = "ServiceBusConnectionString")] ServiceBusReceivedMessage message,
		ServiceBusMessageActions messageActions)
	{
		_logger.LogInformation("Message ID: {id}", message.MessageId);
		_logger.LogInformation("Message Body: {body}", message.Body);
		_logger.LogInformation("Message Content-Type: {contentType}", message.ContentType);

		InventoryEntity? inventoryEntity = message.ToInventoryEntity();

		// Complete the message
		await messageActions.CompleteMessageAsync(message);

		return inventoryEntity;

	}

}
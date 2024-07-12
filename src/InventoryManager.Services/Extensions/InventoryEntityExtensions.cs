using Azure.Messaging.ServiceBus;
using Remanufacturing.InventoryManager.Entities;
using Remanufacturing.Messages;
using System.Text.Json;

namespace Remanufacturing.InventoryManager.Extensions;

public static class InventoryEntityExtensions
{

	public static InventoryEntity? ToInventoryEntity(this ServiceBusReceivedMessage serviceBusReceivedMessage)
	{
		ArgumentException.ThrowIfNullOrWhiteSpace(nameof(serviceBusReceivedMessage));
		IServiceBusMessage? serviceBusMessage = JsonSerializer.Deserialize<IServiceBusMessage>(serviceBusReceivedMessage.Body)
			?? throw new ArgumentException("The message body is not property formatted.", nameof(serviceBusReceivedMessage));
		if (serviceBusMessage.MessageType != MessageTypes.OrderNextCore)
			throw new ArgumentException("The message type is not OrderNextCore.", nameof(serviceBusReceivedMessage));
		OrderNextCoreMessage orderNextCoreMessage = (OrderNextCoreMessage)serviceBusMessage;
		return new()
		{
			Id = orderNextCoreMessage.MessageId,
			FinishedProductId = orderNextCoreMessage.FinishedProductId!,
			CoreId = orderNextCoreMessage.CoreId!,
			Status = "Core Ordered",
			StatusDetail = null,
			StatusDateTime = orderNextCoreMessage.RequestDateTime
		};
	}

}
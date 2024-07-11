using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Remanufacturing.NotificationManager.Services;

namespace Remanufacturing.NotificationManager.Functions;

public class NextCoreInTransit
{
	private readonly ILogger<NextCoreInTransit> _logger;
	private readonly NotificationServices _notificationServices;

	public NextCoreInTransit(ILogger<NextCoreInTransit> logger, NotificationServices notificationServices)
	{
		_logger = logger;
		_notificationServices = notificationServices;
	}

	[Function(nameof(NextCoreInTransit))]
	public async Task Run(
		[ServiceBusTrigger("%NextCoreInTransit_TopicName%", "%NextCoreInTransit_Subscription", Connection = "ServiceBusConnectionString")] ServiceBusReceivedMessage message,
		ServiceBusMessageActions messageActions)
	{

		_logger.LogInformation("Message ID: {id}", message.MessageId);
		_logger.LogInformation("Message Body: {body}", message.Body);
		_logger.LogInformation("Message Content-Type: {contentType}", message.ContentType);

		await _notificationServices.NotifyNextCoreInTransitAsync(message);

		// Complete the message
		await messageActions.CompleteMessageAsync(message);

	}

}
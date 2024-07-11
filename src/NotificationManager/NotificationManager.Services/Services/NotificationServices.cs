using Azure;
using Azure.Communication.Email;
using Azure.Data.Tables;
using Azure.Messaging.ServiceBus;
using Remanufacturing.Messages;
using Remanufacturing.NotificationManager.TableEntities;
using System.Text.Json;

namespace Remanufacturing.NotificationManager.Services;

public class NotificationServices(string CommunicationServicesConnectionString, TableClient tableClient)
{

	private readonly string _communicationServicesConnectionString = CommunicationServicesConnectionString;
	private readonly TableClient _tableClient = tableClient;

	public async Task<string> NotifyNextCoreInTransitAsync(ServiceBusReceivedMessage serviceBusMessage)
	{
		IServiceBusMessage? deserializedMessage = JsonSerializer.Deserialize<IServiceBusMessage>(serviceBusMessage.Body.ToString())
			?? throw new ArgumentNullException(nameof(serviceBusMessage), "Invalid message");
		if (deserializedMessage.MessageType != MessageTypes.NextCoreInTransit)
			throw new ArgumentOutOfRangeException(nameof(serviceBusMessage), "Invalid message type");
		NextCoreInTransitMessage nextCoreInTransitMessage = (NextCoreInTransitMessage)deserializedMessage;
		ContactListTableEntity contactListTableEntity = await GetContactListAsync(nextCoreInTransitMessage.PodId, MessageTypes.NextCoreInTransit);
		string subject = "Next Core In Transit";
		string htmlContent = $"<p>Core ID: {nextCoreInTransitMessage.CoreId}</p><p>Status: {nextCoreInTransitMessage.Status}</p><p>Status Date Time: {nextCoreInTransitMessage.StatusDateTime}</p>";
		string plainTextContent = $"Core ID: {nextCoreInTransitMessage.CoreId}\nStatus: {nextCoreInTransitMessage.Status}\nStatus Date Time: {nextCoreInTransitMessage.StatusDateTime}";
		return await SendEmailAsync(subject, htmlContent, plainTextContent, contactListTableEntity.EmailAddress);
	}

	private async Task<ContactListTableEntity> GetContactListAsync(string podId, string messageType)
		=> await _tableClient.GetEntityAsync<ContactListTableEntity>(rowKey: podId, partitionKey: messageType);

	private async Task<string> SendEmailAsync(
		string subject,
		string htmlContent,
		string plainTextContent,
		string recipientAddress)
	{
		EmailClient emailClient = new(_communicationServicesConnectionString);
		EmailSendOperation emailSendOperation = await emailClient.SendAsync(
			WaitUntil.Completed,
			"NoticeSenderAddress",
			recipientAddress,
			subject,
			htmlContent,
			plainTextContent);
		return emailSendOperation.Id;
	}

}
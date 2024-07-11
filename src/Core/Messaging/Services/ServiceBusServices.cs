using Azure.Messaging.ServiceBus;
using Remanufacturing.Exceptions;
using System.Text;
using System.Text.Json;

namespace Remanufacturing.Services;

/// <summary>
/// Helper methods for sending messages to a Service Bus topic.
/// </summary>
public class ServiceBusServices
{

	/// <summary>
	/// Sends a single message to a Service Bus topic.
	/// </summary>
	/// <typeparam name="T">The type of the message value.</typeparam>
	/// <param name="serviceBusClient">The Service Bus client.</param>
	/// <param name="topicName">The name of the topic.</param>
	/// <param name="value">The value to be serialized into a message to be sent to the Service Bus topic.</param>
	public static async Task SendMessageAsync<T>(ServiceBusClient serviceBusClient, string topicName, T value)
	{
		ServiceBusSender sender = serviceBusClient.CreateSender(topicName);
		ServiceBusMessage serviceBusMessage = new(Encoding.UTF8.GetBytes(JsonSerializer.Serialize(value)));
		await sender.SendMessageAsync(serviceBusMessage);
	}

	/// <summary>
	/// Sends a batch of messages to a Service Bus topic.
	/// </summary>
	/// <typeparam name="T">The type of the message values.</typeparam>
	/// <param name="serviceBusClient">The Service Bus client.</param>
	/// <param name="topicName">The name of the topic.</param>
	/// <param name="values">The Collection of message values to be serialized into message to be sent to the Service Bus topic.</param>
	/// <exception cref="MessageTooLargeForBatchException">Thrown when a message is too large to fit in the batch.</exception>
	public static async Task SendMessageBatchAsync<T>(ServiceBusClient serviceBusClient, string topicName, IEnumerable<T> values)
	{
		await using ServiceBusSender sender = serviceBusClient.CreateSender(topicName);
		using ServiceBusMessageBatch messageBatch = await sender.CreateMessageBatchAsync();
		for (int i = 0; i < values.Count(); i++)
		{
			string message = JsonSerializer.Serialize<T>(values.ElementAt(i));
			if (!messageBatch.TryAddMessage(new ServiceBusMessage(message)))
				throw new MessageTooLargeForBatchException(i);
		}
		await sender.SendMessagesAsync(messageBatch);
	}

}
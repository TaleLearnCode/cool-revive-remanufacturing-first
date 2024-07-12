using Azure.Messaging.ServiceBus;

namespace Remanufacturing.OrderNextCore.Services;

public class OrderNextCoreServicesOptions
{
	public ServiceBusClient ServiceBusClient { get; set; } = null!;
	public string GetNextCoreTopicName { get; set; } = null!;
	public string OrderNextCoreTopicName { get; set; } = null!;
	public Dictionary<string, Uri> GetNextCoreUris { get; set; } = [];
}
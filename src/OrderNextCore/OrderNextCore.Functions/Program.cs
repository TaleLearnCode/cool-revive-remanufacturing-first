using Azure.Messaging.ServiceBus;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Remanufacturing.OrderNextCore.Services;

OrderNextCoreServicesOptions orderNextCoreServicesOptions = new()
{
	ServiceBusClient = new ServiceBusClient(Environment.GetEnvironmentVariable("ServiceBusConnectionString")!),
	GetNextCoreTopicName = Environment.GetEnvironmentVariable("GetNextCoreTopicName")!,
	OrderNextCoreTopicName = Environment.GetEnvironmentVariable("OrderNextCoreTopicName")!
};

IHost host = new HostBuilder()
	.ConfigureFunctionsWebApplication()
	.ConfigureServices(services =>
	{
		services.AddApplicationInsightsTelemetryWorkerService();
		services.ConfigureFunctionsApplicationInsights();
		services.AddHttpClient();
		services.AddSingleton(new OrderNextCoreServices(orderNextCoreServicesOptions));
	})
	.Build();

host.Run();
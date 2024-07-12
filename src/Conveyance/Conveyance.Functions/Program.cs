using Azure.Data.Tables;
using Conveyance.Services;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;

TableServiceClient tableServiceClient = new(Environment.GetEnvironmentVariable("StorageConnectionString"!));
TableClient tableClient = tableServiceClient.GetTableClient(Environment.GetEnvironmentVariable("ConveyanceMissionTableName"!));

IHost host = new HostBuilder()
	.ConfigureFunctionsWebApplication()
	.ConfigureServices(services =>
	{
		services.AddApplicationInsightsTelemetryWorkerService();
		services.ConfigureFunctionsApplicationInsights();
		services.AddSingleton(new ConveyanceServices(tableClient, new Uri(Environment.GetEnvironmentVariable("NextCoreInTransitUrl")!)));
	})
	.Build();

host.Run();
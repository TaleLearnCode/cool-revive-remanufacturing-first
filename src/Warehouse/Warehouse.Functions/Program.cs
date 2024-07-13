using Azure.Data.Tables;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Warehouse.Services;

TableServiceClient tableServiceClient = new(Environment.GetEnvironmentVariable("StorageConnectionString"!));
TableClient warehouseTableClient = tableServiceClient.GetTableClient(Environment.GetEnvironmentVariable("WarehouseTableName"!));
TableClient conveyanceTableClient = tableServiceClient.GetTableClient(Environment.GetEnvironmentVariable("ConveyanceMissionTableName"!));

IHost host = new HostBuilder()
	.ConfigureFunctionsWebApplication()
	.ConfigureServices(services =>
	{
		services.AddApplicationInsightsTelemetryWorkerService();
		services.ConfigureFunctionsApplicationInsights();
		services.AddHttpClient();
		services.AddSingleton(new WarehouseServices(warehouseTableClient, conveyanceTableClient, new Uri(Environment.GetEnvironmentVariable("NextCoreInTransitUrl")!)));
	})
	.Build();

host.Run();
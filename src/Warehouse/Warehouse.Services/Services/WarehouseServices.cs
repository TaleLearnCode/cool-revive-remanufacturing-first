using Azure.Data.Tables;
using System.Text;
using System.Text.Json;
using Warehouse.Messages;
using Warehouse.TableEntities;

namespace Warehouse.Services;

public class WarehouseServices(TableClient warehouseTableClient, TableClient conveyanceTableClient, Uri nextCoreInTransitUrl)
{

	private readonly TableClient _warehouseTableClient = warehouseTableClient;
	private readonly TableClient _conveyanceTableClient = conveyanceTableClient;
	private readonly Uri _nextCoreInTransitUrl = nextCoreInTransitUrl;

	public async Task StartPickingOrdersAsync(HttpClient httpClient, string warehouseId)
	{
		List<PickOrderTableEntity> pickOrders = GetPickOrders(warehouseId, "pending");
		foreach (PickOrderTableEntity pickOrder in pickOrders)
		{
			PickOrderTableEntity updatedPickOrder = await UpdateOrderStatus(pickOrder, "started");
			await NotifyCoreInTransitAsync(httpClient, updatedPickOrder);
		}
	}

	public async Task CompletePickingOrdersAsync(HttpClient httpClient, string warehouseId)
	{
		List<PickOrderTableEntity> pickOrders = GetPickOrders(warehouseId, "pending");
		foreach (PickOrderTableEntity pickOrder in pickOrders)
		{
			PickOrderTableEntity updatedPickOrder = await UpdateOrderStatus(pickOrder, "completed");
			await NotifyCoreInTransitAsync(httpClient, updatedPickOrder);
			await DeliverCoreToConveyanceAsync(updatedPickOrder);
		}
	}

	private List<PickOrderTableEntity> GetPickOrders(string warehouseId, string status)
		=> [.. _warehouseTableClient.Query<PickOrderTableEntity>(x => x.PartitionKey == warehouseId && x.PickStatus == status)];

	private async Task<PickOrderTableEntity> UpdateOrderStatus(PickOrderTableEntity pickOrder, string status)
	{
		pickOrder.PickStatus = status;
		pickOrder.ETag = new Azure.ETag("*");
		await _warehouseTableClient.UpdateEntityAsync(pickOrder, pickOrder.ETag);
		return pickOrder;
	}

	private async Task NotifyCoreInTransitAsync(HttpClient httpClient, PickOrderTableEntity pickOrder)
	{

		string status = pickOrder.OrderStatus switch
		{
			"pending" => "Warehouse Pick Order Pending",
			"started" => "Warehouse Pick Order Started",
			"completed" => "Warehouse Pick Order Completed",
			_ => "Warehouse Pick Order Unknown",
		};

		NextCoreInTransitMessage nextCoreInTransitMessage = new()
		{
			PodId = pickOrder.PodId,
			CoreId = pickOrder.CoreId,
			Status = status,
			StatusDateTime = DateTime.UtcNow
		};
		string serializedMessage = JsonSerializer.Serialize(nextCoreInTransitMessage);

		HttpRequestMessage request = new(HttpMethod.Post, _nextCoreInTransitUrl)
		{
			Content = new StringContent(serializedMessage, Encoding.UTF8, "application/json")
		};

		HttpResponseMessage response = await httpClient.SendAsync(request);

		response.EnsureSuccessStatusCode(); // TODO: In a real-world scenario, you would want to handle non-success status codes.

	}

	private async Task DeliverCoreToConveyanceAsync(PickOrderTableEntity pickOrder)
	{

		string conveyanceUnit = "Wally";
		string missionId = Guid.NewGuid().ToString();
		ConveyanceMissionTableEntity conveyanceMissionTableEntity = new()
		{
			MissionId = missionId,
			ConveyanceUnit = conveyanceUnit,
			DispatchDateTime = DateTime.UtcNow,
			Origin = pickOrder.WarehouseId,
			Destination = pickOrder.PodId,
			TagId = pickOrder.CoreId,
			PartitionKey = conveyanceUnit,
			RowKey = missionId
		};

		await _conveyanceTableClient.AddEntityAsync(conveyanceMissionTableEntity);

	}

}
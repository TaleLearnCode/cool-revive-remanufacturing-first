using Microsoft.Azure.Cosmos;
using Remanufacturing.InventoryManager.Entities;

namespace Remanufacturing.InventoryManager.Services;

public class InventoryServices(Container inventory)
{

	private readonly Container _inventory = inventory;


	public async Task EventSourceChangeFeedHandlerAsync(IReadOnlyList<InventoryEntity> input)
	{
		List<InventoryEntity>? latestEntities = input
			.GroupBy(entity => entity.FinishedProductId)
			.Select(group => group.OrderByDescending(entity => entity.StatusDateTime).First())
			.ToList();
		if (latestEntities is not null && latestEntities.Count > 0)
			foreach (InventoryEntity inventoryEntity in input)
				await UpdateInventoryStatusAsync(inventoryEntity);
	}

	private async Task UpdateInventoryStatusAsync(InventoryEntity eventSource)
	{
		InventoryEntity? inventoryEntity = await GetInventoryEntityAsync(eventSource.Id);
		if (inventoryEntity is null)
		{
			await _inventory.CreateItemAsync(eventSource, new PartitionKey(eventSource.CoreId));
		}
		else
		{
			if (inventoryEntity.Status == eventSource.Status && inventoryEntity.StatusDetail == eventSource.StatusDetail) return;
			inventoryEntity.Status = eventSource.Status;
			inventoryEntity.StatusDetail = eventSource.StatusDetail;
			inventoryEntity.StatusDateTime = DateTime.Now;
			await _inventory.UpsertItemAsync(inventoryEntity);
		}
	}

	private async Task<InventoryEntity?> GetInventoryEntityAsync(string id)
	{
		try
		{
			ItemResponse<InventoryEntity> response = await _inventory.ReadItemAsync<InventoryEntity>(id, new PartitionKey(id));
			return response.Resource;
		}
		catch (CosmosException ex) when (ex.StatusCode == System.Net.HttpStatusCode.NotFound)
		{
			return null;
		}
	}

}
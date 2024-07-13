#nullable disable

using Azure;
using Azure.Data.Tables;

namespace Warehouse.TableEntities;

public class PickOrderTableEntity : ITableEntity
{

	public string WarehouseId { get; set; }
	public string OrderId { get; set; }
	public string OrderStatus { get; set; }
	public string PodId { get; set; }
	public string CoreId { get; set; }
	public string PickStatus { get; set; } = "pending";

	public string PartitionKey { get; set; }
	public string RowKey { get; set; }
	public DateTimeOffset? Timestamp { get; set; }
	public ETag ETag { get; set; }

}
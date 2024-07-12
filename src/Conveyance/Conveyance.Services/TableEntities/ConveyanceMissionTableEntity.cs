#nullable disable

using Azure;
using Azure.Data.Tables;

namespace Conveyance.TableEntities;

public class ConveyanceMissionTableEntity : ITableEntity
{

	public string MissionId { get; set; } = null!;
	public string ConveyanceUnit { get; set; } = null!;
	public DateTime DispatchDateTime { get; set; }
	public DateTime MissionStart { get; set; }
	public DateTime? MissionEnd { get; set; }
	public string Origin { get; set; }
	public string Destination { get; set; }
	public string MissionStatus { get; set; }

	public string PartitionKey { get; set; }
	public string RowKey { get; set; }
	public DateTimeOffset? Timestamp { get; set; }
	public ETag ETag { get; set; }

}
#nullable disable

using Azure;
using Azure.Data.Tables;

namespace Remanufacturing.NotificationManager.TableEntities;

public class ContactListTableEntity : ITableEntity
{

	public string PartitionKey { get; set; }
	public string RowKey { get; set; }
	public DateTimeOffset? Timestamp { get; set; }
	public ETag ETag { get; set; }

	public string EmailAddress { get; set; }

}
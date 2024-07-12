using System.Text.Json.Serialization;

namespace Remanufacturing.InventoryManager.Entities;

public class InventoryEntity
{
	[JsonPropertyName("id")]
	public string Id { get; set; } = null!;
	[JsonPropertyName("finishedProductId")]
	public string FinishedProductId { get; set; } = null!;
	[JsonPropertyName("podId")]
	public string PodId { get; set; } = null!;
	[JsonPropertyName("coreId")]
	public string CoreId { get; set; } = null!;
	[JsonPropertyName("status")]
	public string Status { get; set; } = null!;
	[JsonPropertyName("statusDetail")]
	public string? StatusDetail { get; set; }
	[JsonPropertyName("statusDateTime")]
	public DateTime StatusDateTime { get; set; } = DateTime.Now;
}
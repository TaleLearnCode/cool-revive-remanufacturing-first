namespace Conveyance.Messages;

public class NextCoreInTransitMessage
{

	/// <summary>
	/// Gets or sets the tracking identifier for the message.
	/// </summary>
	public string MessageId { get; set; } = Guid.NewGuid().ToString();

	/// <summary>
	/// Gets or sets the type of the message.
	/// </summary>
	public string MessageType { get; set; } = "NextCoreInTransit";

	/// <summary>
	/// Gets or sets the identifier of the pod the core is for.
	/// </summary>
	public string PodId { get; set; } = null!;

	/// <summary>
	/// Gets or sets the identifier of the core.
	/// </summary>
	public string CoreId { get; set; } = null!;

	/// <summary>
	/// Gets or sets the status of the transportation.
	/// </summary>
	public string Status { get; set; } = null!;

	/// <summary>
	/// Gets or sets the date and time of the status.
	/// </summary>
	public DateTime StatusDateTime { get; set; }

}
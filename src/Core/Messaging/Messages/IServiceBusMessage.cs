namespace Remanufacturing.Messages;

/// <summary>
/// Interface for Cool Revive Remanufacturing messages.
/// </summary>
public interface IServiceBusMessage
{

	/// <summary>
	/// Gets or sets the tracking identifier for the message.
	/// </summary>
	string MessageId { get; set; }

	/// <summary>
	/// Gets or sets the type of the message.
	/// </summary>
	string MessageType { get; set; }

}
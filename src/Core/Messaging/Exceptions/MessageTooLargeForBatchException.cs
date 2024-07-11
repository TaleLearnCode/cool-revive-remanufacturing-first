namespace Remanufacturing.Exceptions;

public class MessageTooLargeForBatchException : Exception
{
	public MessageTooLargeForBatchException() : base("One of the messages is too large to fit in the batch.") { }
	public MessageTooLargeForBatchException(int messageIndex) : base($"The message {messageIndex} is too large to fit in the batch.") { }
	public MessageTooLargeForBatchException(string message) : base(message) { }
	public MessageTooLargeForBatchException(string message, Exception innerException) : base(message, innerException) { }
}
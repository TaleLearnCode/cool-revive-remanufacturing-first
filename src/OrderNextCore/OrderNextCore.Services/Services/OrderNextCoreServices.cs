using Remanufacturing.Messages;
using Remanufacturing.Responses;
using Remanufacturing.Services;
using System.Net;
using System.Text.Json;

namespace Remanufacturing.OrderNextCore.Services;

public class OrderNextCoreServices(OrderNextCoreServicesOptions options)
{

	private readonly OrderNextCoreServicesOptions _servicesOptions = options;

	public async Task<IResponse> RequestNextCoreInformationAsync(OrderNextCoreMessage orderNextCoreMessage, string instance)
	{
		try
		{
			ArgumentException.ThrowIfNullOrEmpty(orderNextCoreMessage.PodId, nameof(orderNextCoreMessage.PodId));
			if (orderNextCoreMessage.CoreId != null)
				await OrderNextCoreAsync(orderNextCoreMessage, instance);
			if (orderNextCoreMessage.RequestDateTime == default)
				orderNextCoreMessage.RequestDateTime = DateTime.UtcNow;
			await ServiceBusServices.SendMessageAsync(_servicesOptions.ServiceBusClient, _servicesOptions.GetNextCoreTopicName, orderNextCoreMessage);
			return new StandardResponse()
			{
				Type = "https://httpstatuses.com/201", // HACK: In a real-world scenario, you would want to provide a more-specific URI reference that identifies the response type.
				Title = "Request for next core id sent.",
				Status = HttpStatusCode.Created,
				Detail = "The request for the next core id has been sent to the Production Schedule.",
				Instance = instance,
				Extensions = new Dictionary<string, object>()
				{
					{ "PodId", orderNextCoreMessage.PodId },
				}
			};
		}
		catch (ArgumentException ex)
		{
			return new ProblemDetails(ex, instance);
		}
		catch (Exception ex)
		{
			return new ProblemDetails()
			{
				Type = "https://httpstatuses.com/500", // HACK: In a real-world scenario, you would want to provide a more-specific URI reference that identifies the response type.
				Title = "An error occurred while sending the message to the Service Bus",
				Status = HttpStatusCode.InternalServerError,
				Detail = ex.Message, // HACK: In a real-world scenario, you would not want to expose the exception message to the client.
				Instance = instance
			};
		}
	}

	public async Task<IResponse> OrderNextCoreAsync(OrderNextCoreMessage nextCoreRequestMessage, string instance)
	{
		try
		{
			ArgumentException.ThrowIfNullOrEmpty(nextCoreRequestMessage.PodId, nameof(nextCoreRequestMessage.PodId));
			ArgumentException.ThrowIfNullOrEmpty(nextCoreRequestMessage.CoreId, nameof(nextCoreRequestMessage.CoreId));
			if (nextCoreRequestMessage.RequestDateTime == default)
				nextCoreRequestMessage.RequestDateTime = DateTime.UtcNow;
			await ServiceBusServices.SendMessageAsync(_servicesOptions.ServiceBusClient, _servicesOptions.OrderNextCoreTopicName, nextCoreRequestMessage);
			return new StandardResponse()
			{
				Type = "https://httpstatuses.com/201", // HACK: In a real-world scenario, you would want to provide a more-specific URI reference that identifies the response type.
				Title = "Request for next core sent.",
				Status = HttpStatusCode.Created,
				Detail = "The request for the next core has been sent to the warehouse.",
				Instance = instance,
				Extensions = new Dictionary<string, object>()
				{
					{ "PodId", nextCoreRequestMessage.PodId },
					{ "CoreId", nextCoreRequestMessage.CoreId }
				}
			};
		}
		catch (ArgumentException ex)
		{
			return new ProblemDetails(ex, instance);
		}
		catch (Exception ex)
		{
			return new ProblemDetails()
			{
				Type = "https://httpstatuses.com/500", // HACK: In a real-world scenario, you would want to provide a more-specific URI reference that identifies the response type.
				Title = "An error occurred while sending the message to the Service Bus",
				Status = HttpStatusCode.InternalServerError,
				Detail = ex.Message, // HACK: In a real-world scenario, you would not want to expose the exception message to the client.
				Instance = instance
			};
		}
	}

	public async Task<IResponse> GetNextCoreAsync(HttpClient httpClient, OrderNextCoreMessage orderNextCoreMessage)
	{
		try
		{
			if (!_servicesOptions.GetNextCoreUris.TryGetValue(orderNextCoreMessage.PodId, out Uri? getNextCoreUrl))
				throw new ArgumentOutOfRangeException(nameof(orderNextCoreMessage.PodId), $"The pod ID '{orderNextCoreMessage.PodId}' is not valid.");
			HttpResponseMessage httpResponse = await httpClient.GetAsync(getNextCoreUrl);
			httpResponse.EnsureSuccessStatusCode();
			string responseBody = await httpResponse.Content.ReadAsStringAsync();
			IResponse? response = JsonSerializer.Deserialize<IResponse>(responseBody);
			return response ?? throw new InvalidOperationException("The response from the GetNextCore service was not in the expected format.");
		}
		catch (ArgumentException ex)
		{
			return new ProblemDetails(ex);
		}
		catch (Exception ex)
		{
			return new ProblemDetails()
			{
				Type = "https://httpstatuses.com/500", // HACK: In a real-world scenario, you would want to provide a more-specific URI reference that identifies the response type.
				Title = "An error occurred while sending the message to the Service Bus",
				Status = HttpStatusCode.InternalServerError,
				Detail = ex.Message // HACK: In a real-world scenario, you would not want to expose the exception message to the client.
			};
		}
	}

}
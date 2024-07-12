using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;
using Remanufacturing.Messages;
using Remanufacturing.OrderNextCore.Services;
using Remanufacturing.Responses;
using System.Net;
using System.Text.Json;

namespace Remanufacturing.OrderNextCore.Functions;

public class GetNextCore(ILogger<GetNextCore> logger, OrderNextCoreServices orderNextCoreServices)
{

	private readonly ILogger<GetNextCore> _logger = logger;
	private readonly OrderNextCoreServices _orderNextCoreServices = orderNextCoreServices;

	[Function("GetNextCore")]
	public async Task<IActionResult> RunAsync([HttpTrigger(AuthorizationLevel.Function, "post")] HttpRequest request)
	{
		string requestBody = await new StreamReader(request.Body).ReadToEndAsync();
		OrderNextCoreMessage? nextCoreRequestMessage = JsonSerializer.Deserialize<OrderNextCoreMessage>(requestBody);
		if (nextCoreRequestMessage is not null)
		{
			_logger.LogInformation("Get next core for Pod '{podId}'", nextCoreRequestMessage.PodId);
			IResponse response = await _orderNextCoreServices.RequestNextCoreInformationAsync(nextCoreRequestMessage, request.HttpContext.TraceIdentifier);
			return new ObjectResult(response) { StatusCode = (int)HttpStatusCode.OK };
		}
		else
		{
			_logger.LogWarning("Invalid request body.");
			return new BadRequestObjectResult("Invalid request body.");
		}
	}

}
using Azure.Data.Tables;
using Conveyance.TableEntities;
using System.Text;
using System.Text.Json;

namespace Conveyance.Services;

public class ConveyanceServices(TableClient tableClient, Uri nextCoreInTransitUrl)
{

	private readonly TableClient _tableClient = tableClient;
	private readonly Uri _nextCoreInTransitUrl = nextCoreInTransitUrl;

	public async Task StartMissionsAsync(HttpClient httpClient, string conveyanceUnit)
	{
		List<ConveyanceMissionTableEntity> missions = [.. _tableClient.Query<ConveyanceMissionTableEntity>(x => x.PartitionKey == conveyanceUnit && x.MissionStatus == "pending")];
		foreach (ConveyanceMissionTableEntity mission in missions)
		{
			mission.MissionStatus = "started";
			mission.MissionStart = DateTime.UtcNow;
			mission.ETag = new Azure.ETag("*");
			await _tableClient.UpdateEntityAsync(mission, mission.ETag);
			await NotifyCoreInTransit(httpClient, mission);
		}
	}

	private async Task NotifyCoreInTransit(HttpClient httpClient, ConveyanceMissionTableEntity conveyanceMission)
	{
		HttpRequestMessage request = new HttpRequestMessage(HttpMethod.Post, _nextCoreInTransitUrl);
		string serializedMission = JsonSerializer.Serialize(conveyanceMission);
		request.Content = new StringContent(serializedMission, Encoding.UTF8, "application/json");
		HttpResponseMessage response = await httpClient.SendAsync(request);
		response.EnsureSuccessStatusCode(); // TODO: In a real-world scenario, you would want to handle non-success status codes.
	}

}
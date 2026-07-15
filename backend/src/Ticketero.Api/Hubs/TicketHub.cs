using Microsoft.AspNetCore.SignalR;

namespace Ticketero.Api.Hubs;

public class TicketHub : Hub
{
    public async Task JoinAreaGroup(int areaId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"area_{areaId}");
    }

    public async Task LeaveAreaGroup(int areaId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"area_{areaId}");
    }

    public async Task RequestQueueStatus()
    {
        await Clients.Caller.SendAsync("QueueStatusRequested");
    }

    public override async Task OnConnectedAsync()
    {
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await base.OnDisconnectedAsync(exception);
    }
}

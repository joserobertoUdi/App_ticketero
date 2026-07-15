using Microsoft.AspNetCore.SignalR;
using Ticketero.Api.Hubs;
using Ticketero.Application.Interfaces;

namespace Ticketero.Api.Services;

public class TicketNotificationService : ITicketNotificationService
{
    private readonly IHubContext<TicketHub> _hubContext;

    public TicketNotificationService(IHubContext<TicketHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task NotifyTicketCreated(object ticketData)
    {
        await _hubContext.Clients.All.SendAsync("TicketCreated", ticketData);
    }

    public async Task NotifyTicketCalled(object ticketData)
    {
        await _hubContext.Clients.All.SendAsync("TicketCalled", ticketData);
    }

    public async Task NotifyTicketStarted(object ticketData)
    {
        await _hubContext.Clients.All.SendAsync("TicketStarted", ticketData);
    }

    public async Task NotifyTicketCompleted(object ticketData)
    {
        await _hubContext.Clients.All.SendAsync("TicketCompleted", ticketData);
    }

    public async Task NotifyTicketCancelled(object ticketData)
    {
        await _hubContext.Clients.All.SendAsync("TicketCancelled", ticketData);
    }

    public async Task NotifyQueueUpdated(int areaId, int pendingCount)
    {
        await _hubContext.Clients.Group($"area_{areaId}").SendAsync("QueueUpdated", new
        {
            areaId,
            pendientes = pendingCount
        });
    }
}

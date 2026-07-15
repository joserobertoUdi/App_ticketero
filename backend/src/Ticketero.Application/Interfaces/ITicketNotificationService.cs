namespace Ticketero.Application.Interfaces;

public interface ITicketNotificationService
{
    Task NotifyTicketCreated(object ticketData);
    Task NotifyTicketCalled(object ticketData);
    Task NotifyTicketStarted(object ticketData);
    Task NotifyTicketCompleted(object ticketData);
    Task NotifyTicketCancelled(object ticketData);
    Task NotifyQueueUpdated(int areaId, int pendingCount);
}

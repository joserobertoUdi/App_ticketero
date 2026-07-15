using Ticketero.Domain.Entities;

namespace Ticketero.Domain.Interfaces;

public interface ITicketRepository
{
    Task<Ticket> GetByIdAsync(int id);
    Task<IEnumerable<Ticket>> GetPendingByAreaAsync(int areaId);
    Task<Ticket?> GetCurrentByUserAsync(int userId);
    Task<IEnumerable<Ticket>> GetHistoryByUserAndDateAsync(int userId, DateTime fecha);
    Task<Ticket> AddAsync(Ticket ticket);
    Task UpdateAsync(Ticket ticket);
    Task<string> GetNextTicketCodeAsync(int areaId);
    Task<int> GetPendingCountByAreaAsync(int areaId);
    Task<IEnumerable<Ticket>> GetAllInRangeAsync(DateTime inicio, DateTime fin);
    Task AddAttentionLogAsync(AttentionLog log);
    Task UpdateAttentionLogStartAsync(int ticketId, int userId, DateTime iniciadoAt);
    Task CompleteAttentionLogAsync(int ticketId, int userId, DateTime completadoAt, string? observacion);
    Task CancelAttentionLogAsync(int ticketId, string motivo);
}

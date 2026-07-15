using Ticketero.Application.DTOs;

namespace Ticketero.Application.Interfaces;

public interface ITicketService
{
    Task<TicketDto?> GetTicketByIdAsync(int id);
    Task<TicketDto> CreateTicketAsync(int areaId);
    Task<IEnumerable<TicketDto>> GetPendingTicketsAsync(int areaId);
    Task<TicketDto> CallTicketAsync(int ticketId, int userId);
    Task<TicketDto> StartAttentionAsync(int ticketId, int userId);
    Task<TicketDto> CompleteTicketAsync(int ticketId, int userId, string? observacion);
    Task<TicketDto> CancelTicketAsync(int ticketId, string? motivo);
    Task<TicketDto?> GetCurrentTicketAsync(int userId);
    Task<IEnumerable<TicketDto>> GetAttentionHistoryAsync(int userId, DateTime fecha);
}

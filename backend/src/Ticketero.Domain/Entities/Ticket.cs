using Ticketero.Domain.Enums;

namespace Ticketero.Domain.Entities;

public class Ticket
{
    public int Id { get; set; }
    public string CodigoTicket { get; set; } = string.Empty;
    public TicketType TipoTicket { get; set; }
    public int AreaId { get; set; }
    public TicketStatus Status { get; set; } = TicketStatus.Pendiente;
    public int? LlamadoPorUserId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public Area Area { get; set; } = null!;
    public User? LlamadoPorUser { get; set; }
    public AttentionLog? AttentionLog { get; set; }
}

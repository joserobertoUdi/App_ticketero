namespace Ticketero.Domain.Entities;

public class AttentionLog
{
    public int Id { get; set; }
    public int TicketId { get; set; }
    public int UserId { get; set; }
    public DateTime LlamadoAt { get; set; }
    public DateTime? IniciadoAt { get; set; }
    public DateTime? CompletadoAt { get; set; }
    public int? TiempoSegundos { get; set; }
    public string? Observacion { get; set; }

    public Ticket Ticket { get; set; } = null!;
    public User User { get; set; } = null!;
}

using Ticketero.Domain.Enums;

namespace Ticketero.Domain.Entities;

public class User
{
    public int Id { get; set; }
    public string NombreUsuario { get; set; } = string.Empty;
    public string NombreCompleto { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public UserRole Rol { get; set; }
    public int? AreaId { get; set; }
    public bool Activo { get; set; } = true;
    public DateTime? UltimoAcceso { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public Area? Area { get; set; }
    public ICollection<Ticket> LlamadosTickets { get; set; } = new List<Ticket>();
    public ICollection<AttentionLog> AttentionLogs { get; set; } = new List<AttentionLog>();
}

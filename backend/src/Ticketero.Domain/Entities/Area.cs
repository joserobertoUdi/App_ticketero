namespace Ticketero.Domain.Entities;

public class Area
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Prefijo { get; set; } = string.Empty;
    public bool Activo { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public DateTime UpdatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<User> Users { get; set; } = new List<User>();
    public ICollection<Ticket> Tickets { get; set; } = new List<Ticket>();
}

namespace Ticketero.Application.DTOs;

public class AreaDto
{
    public int Id { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string Prefijo { get; set; } = string.Empty;
    public bool Activo { get; set; }
}

public class CreateAreaRequest
{
    public string Nombre { get; set; } = string.Empty;
    public string Prefijo { get; set; } = string.Empty;
    public bool Activo { get; set; } = true;
}

public class UpdateAreaRequest
{
    public string? Nombre { get; set; }
    public string? Prefijo { get; set; }
    public bool? Activo { get; set; }
}

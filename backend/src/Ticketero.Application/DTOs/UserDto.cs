namespace Ticketero.Application.DTOs;

public class UserDto
{
    public int Id { get; set; }
    public string NombreUsuario { get; set; } = string.Empty;
    public string NombreCompleto { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public int? AreaId { get; set; }
    public string? AreaNombre { get; set; }
    public bool Activo { get; set; }
    public DateTime? UltimoAcceso { get; set; }
}

public class CreateUserRequest
{
    public string NombreUsuario { get; set; } = string.Empty;
    public string NombreCompleto { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Rol { get; set; } = string.Empty;
    public int? AreaId { get; set; }
}

public class UpdateUserRequest
{
    public string? NombreCompleto { get; set; }
    public int? AreaId { get; set; }
    public bool? Activo { get; set; }
}

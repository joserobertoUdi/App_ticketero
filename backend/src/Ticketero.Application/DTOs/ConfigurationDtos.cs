namespace Ticketero.Application.DTOs;

public class SystemConfigurationDto
{
    public int TiempoEstimadoMinutos { get; set; }
    public int MaxTicketsPorDia { get; set; }
    public string? VideoActual { get; set; }
}

public class UpdateConfigurationRequest
{
    public int? TiempoEstimadoMinutos { get; set; }
    public int? MaxTicketsPorDia { get; set; }
}

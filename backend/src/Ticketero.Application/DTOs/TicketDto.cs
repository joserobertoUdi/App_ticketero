namespace Ticketero.Application.DTOs;

public class TicketDto
{
    public int Id { get; set; }
    public string CodigoTicket { get; set; } = string.Empty;
    public string TipoTicket { get; set; } = string.Empty;
    public int AreaId { get; set; }
    public string AreaNombre { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public int? LlamadoPorUserId { get; set; }
    public string? LlamadoPorUserName { get; set; }
    public DateTime CreadoEn { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? TiempoEsperaSegundos { get; set; }
    public int? TiempoAtencionSegundos { get; set; }
    public string? TiempoAtencionFormateado { get; set; }
}

public class CreateTicketRequest
{
    public int AreaId { get; set; }
}

public class CallTicketRequest
{
    public int UserId { get; set; }
}

public class CompleteTicketRequest
{
    public int UserId { get; set; }
    public string? Observacion { get; set; }
}

public class CancelTicketRequest
{
    public string? Motivo { get; set; }
}

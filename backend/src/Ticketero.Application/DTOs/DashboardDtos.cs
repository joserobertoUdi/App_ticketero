namespace Ticketero.Application.DTOs;

public class DashboardSummaryDto
{
    public int TotalTickets { get; set; }
    public int TotalAtendidos { get; set; }
    public int TotalPendientes { get; set; }
    public int TiempoPromedioAtencion { get; set; }
    public string TiempoPromedioFormateado { get; set; } = string.Empty;
    public int TiempoPromedioEspera { get; set; }
    public string TiempoPromedioEsperaFormateado { get; set; } = string.Empty;
    public PeriodoDto? Periodo { get; set; }
}

public class PeriodoDto
{
    public DateTime Inicio { get; set; }
    public DateTime Fin { get; set; }
}

public class AreaStatsDto
{
    public string Area { get; set; } = string.Empty;
    public int Total { get; set; }
    public int Atendidos { get; set; }
    public int Pendientes { get; set; }
    public int TiempoPromedio { get; set; }
}

public class UserStatsDto
{
    public string Nombre { get; set; } = string.Empty;
    public int TotalAtendidos { get; set; }
    public int TiempoPromedio { get; set; }
    public string Area { get; set; } = string.Empty;
}

public class HourlyBreakdownDto
{
    public int Hora { get; set; }
    public int Total { get; set; }
}

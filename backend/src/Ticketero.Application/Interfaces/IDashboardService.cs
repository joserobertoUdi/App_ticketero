using Ticketero.Application.DTOs;

namespace Ticketero.Application.Interfaces;

public interface IDashboardService
{
    Task<DashboardSummaryDto> GetSummaryAsync(DateTime fechaInicio, DateTime fechaFin);
    Task<IEnumerable<AreaStatsDto>> GetByAreaAsync(DateTime fechaInicio, DateTime fechaFin);
    Task<IEnumerable<UserStatsDto>> GetByUserAsync(DateTime fechaInicio, DateTime fechaFin);
    Task<IEnumerable<HourlyBreakdownDto>> GetHourlyBreakdownAsync(DateTime fecha);
}

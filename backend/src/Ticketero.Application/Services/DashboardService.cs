using Microsoft.Extensions.Caching.Memory;
using Ticketero.Application.DTOs;
using Ticketero.Application.Interfaces;
using Ticketero.Domain.Enums;
using Ticketero.Domain.Interfaces;

namespace Ticketero.Application.Services;

public class DashboardService : IDashboardService
{
    private readonly IUnitOfWork _uow;
    private readonly IMemoryCache _cache;
    private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(2);

    public DashboardService(IUnitOfWork uow, IMemoryCache cache)
    {
        _uow = uow;
        _cache = cache;
    }

    public async Task<DashboardSummaryDto> GetSummaryAsync(DateTime fechaInicio, DateTime fechaFin)
    {
        var cacheKey = $"dashboard_summary_{fechaInicio:yyyyMMdd}_{fechaFin:yyyyMMdd}";
        if (_cache.TryGetValue(cacheKey, out DashboardSummaryDto? cached) && cached is not null)
            return cached;

        var tickets = (await GetAllTicketsInRangeAsync(fechaInicio, fechaFin)).ToList();
        var atendidos = tickets.Where(t => t.Status == TicketStatus.Completado).ToList();
        var completados = tickets.Where(t =>
            t.Status == TicketStatus.Completado && t.AttentionLog?.TiempoSegundos > 0).ToList();

        var result = new DashboardSummaryDto
        {
            TotalTickets = tickets.Count,
            TotalAtendidos = atendidos.Count,
            TotalPendientes = tickets.Count(t => t.Status == TicketStatus.Pendiente),
            TiempoPromedioAtencion = completados.Count > 0
                ? (int)completados.Average(t => t.AttentionLog!.TiempoSegundos!.Value)
                : 0,
            TiempoPromedioFormateado = "",
            TiempoPromedioEspera = 0,
            TiempoPromedioEsperaFormateado = "",
            Periodo = new PeriodoDto { Inicio = fechaInicio, Fin = fechaFin }
        };

        result.TiempoPromedioFormateado = FormatSegundos(result.TiempoPromedioAtencion);

        var conEspera = tickets.Where(t =>
            t.AttentionLog?.LlamadoAt is not null && t.CreatedAt != default).ToList();
        if (conEspera.Count > 0)
        {
            result.TiempoPromedioEspera = (int)conEspera
                .Average(t => (int)(t.AttentionLog!.LlamadoAt - t.CreatedAt).TotalSeconds);
            result.TiempoPromedioEsperaFormateado = FormatSegundos(result.TiempoPromedioEspera);
        }

        _cache.Set(cacheKey, result, CacheDuration);
        return result;
    }

    public async Task<IEnumerable<AreaStatsDto>> GetByAreaAsync(DateTime fechaInicio, DateTime fechaFin)
    {
        var cacheKey = $"dashboard_area_{fechaInicio:yyyyMMdd}_{fechaFin:yyyyMMdd}";
        if (_cache.TryGetValue(cacheKey, out IEnumerable<AreaStatsDto>? cached) && cached is not null)
            return cached;

        var tickets = (await GetAllTicketsInRangeAsync(fechaInicio, fechaFin)).ToList();
        var result = tickets
            .GroupBy(t => t.Area?.Nombre ?? "Sin Area")
            .Select(g =>
            {
                var completados = g.Count(t => t.Status == TicketStatus.Completado);
                var conTiempo = g.Where(t =>
                    t.Status == TicketStatus.Completado && t.AttentionLog?.TiempoSegundos > 0).ToList();
                return new AreaStatsDto
                {
                    Area = g.Key,
                    Total = g.Count(),
                    Atendidos = completados,
                    Pendientes = g.Count(t => t.Status == TicketStatus.Pendiente),
                    TiempoPromedio = conTiempo.Count > 0
                        ? (int)conTiempo.Average(t => t.AttentionLog!.TiempoSegundos!.Value)
                        : 0
                };
            })
            .OrderByDescending(a => a.Total)
            .ToList();

        _cache.Set(cacheKey, result, CacheDuration);
        return result;
    }

    public async Task<IEnumerable<UserStatsDto>> GetByUserAsync(DateTime fechaInicio, DateTime fechaFin)
    {
        var cacheKey = $"dashboard_user_{fechaInicio:yyyyMMdd}_{fechaFin:yyyyMMdd}";
        if (_cache.TryGetValue(cacheKey, out IEnumerable<UserStatsDto>? cached) && cached is not null)
            return cached;

        var tickets = (await GetAllTicketsInRangeAsync(fechaInicio, fechaFin)).ToList();
        var result = tickets
            .Where(t => t.LlamadoPorUser is not null && t.Status == TicketStatus.Completado)
            .GroupBy(t => new { t.LlamadoPorUser!.Id, t.LlamadoPorUser.NombreCompleto, Area = t.LlamadoPorUser.Area?.Nombre ?? "" })
            .Select(g =>
            {
                var conTiempo = g.Where(t => t.AttentionLog?.TiempoSegundos > 0).ToList();
                return new UserStatsDto
                {
                    Nombre = g.Key.NombreCompleto,
                    TotalAtendidos = g.Count(),
                    TiempoPromedio = conTiempo.Count > 0
                        ? (int)conTiempo.Average(t => t.AttentionLog!.TiempoSegundos!.Value)
                        : 0,
                    Area = g.Key.Area
                };
            })
            .OrderByDescending(u => u.TotalAtendidos)
            .ToList();

        _cache.Set(cacheKey, result, CacheDuration);
        return result;
    }

    public async Task<IEnumerable<HourlyBreakdownDto>> GetHourlyBreakdownAsync(DateTime fecha)
    {
        var cacheKey = $"dashboard_hourly_{fecha:yyyyMMdd}";
        if (_cache.TryGetValue(cacheKey, out IEnumerable<HourlyBreakdownDto>? cached) && cached is not null)
            return cached;

        var tickets = (await GetAllTicketsInRangeAsync(fecha.Date, fecha.Date.AddDays(1).AddTicks(-1))).ToList();
        var result = tickets
            .GroupBy(t => t.CreatedAt.Hour)
            .Select(g => new HourlyBreakdownDto { Hora = g.Key, Total = g.Count() })
            .OrderBy(h => h.Hora)
            .ToList();

        _cache.Set(cacheKey, result, CacheDuration);
        return result;
    }

    private async Task<IEnumerable<Domain.Entities.Ticket>> GetAllTicketsInRangeAsync(
        DateTime inicio, DateTime fin)
    {
        return await _uow.Tickets.GetAllInRangeAsync(inicio, fin);
    }

    private static string FormatSegundos(int s)
    {
        var ts = TimeSpan.FromSeconds(s);
        return ts.TotalHours >= 1
            ? $"{(int)ts.TotalHours}:{ts.Minutes:D2}:{ts.Seconds:D2}"
            : $"{ts.Minutes:D2}:{ts.Seconds:D2}";
    }
}

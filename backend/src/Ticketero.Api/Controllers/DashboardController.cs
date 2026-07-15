using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Ticketero.Application.DTOs;
using Ticketero.Application.Interfaces;

namespace Ticketero.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = "administrador")]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _dashboardService;

    public DashboardController(IDashboardService dashboardService)
    {
        _dashboardService = dashboardService;
    }

    [HttpGet("summary")]
    public async Task<ActionResult<DashboardSummaryDto>> GetSummary(
        [FromQuery] DateTime? fechaInicio, [FromQuery] DateTime? fechaFin)
    {
        var inicio = fechaInicio ?? DateTime.Today;
        var fin = fechaFin ?? DateTime.Today.AddDays(1).AddTicks(-1);
        var summary = await _dashboardService.GetSummaryAsync(inicio, fin);
        return Ok(summary);
    }

    [HttpGet("by-area")]
    public async Task<ActionResult> GetByArea(
        [FromQuery] DateTime? fechaInicio, [FromQuery] DateTime? fechaFin)
    {
        var inicio = fechaInicio ?? DateTime.Today;
        var fin = fechaFin ?? DateTime.Today.AddDays(1).AddTicks(-1);
        var areas = await _dashboardService.GetByAreaAsync(inicio, fin);
        return Ok(new { areas });
    }

    [HttpGet("by-user")]
    public async Task<ActionResult> GetByUser(
        [FromQuery] DateTime? fechaInicio, [FromQuery] DateTime? fechaFin)
    {
        var inicio = fechaInicio ?? DateTime.Today;
        var fin = fechaFin ?? DateTime.Today.AddDays(1).AddTicks(-1);
        var usuarios = await _dashboardService.GetByUserAsync(inicio, fin);
        return Ok(new { usuarios });
    }

    [HttpGet("hourly-breakdown")]
    public async Task<ActionResult> GetHourlyBreakdown([FromQuery] DateTime? fecha)
    {
        var date = fecha ?? DateTime.Today;
        var horas = await _dashboardService.GetHourlyBreakdownAsync(date);
        return Ok(new { horas });
    }
}

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Ticketero.Application.DTOs;
using Ticketero.Application.Interfaces;

namespace Ticketero.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class TicketsController : ControllerBase
{
    private readonly ITicketService _ticketService;

    public TicketsController(ITicketService ticketService)
    {
        _ticketService = ticketService;
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<ActionResult<TicketDto>> CreateTicket([FromBody] CreateTicketRequest request)
    {
        try
        {
            var ticket = await _ticketService.CreateTicketAsync(request.AreaId);
            return CreatedAtAction(nameof(GetTicketById), new { id = ticket.Id }, ticket);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("{id}")]
    public async Task<ActionResult<TicketDto>> GetTicketById(int id)
    {
        var ticket = await _ticketService.GetTicketByIdAsync(id);
        if (ticket == null)
            return NotFound();

        return Ok(ticket);
    }

    [HttpGet("pending")]
    public async Task<ActionResult> GetPendingTickets([FromQuery] int areaId)
    {
        var tickets = await _ticketService.GetPendingTicketsAsync(areaId);
        return Ok(new { tickets, totalPendientes = tickets.Count() });
    }

    [HttpPost("{id}/call")]
    [Authorize(Roles = "usuario_atencion,administrador")]
    public async Task<ActionResult<TicketDto>> CallTicket(int id, [FromBody] CallTicketRequest request)
    {
        try
        {
            var ticket = await _ticketService.CallTicketAsync(id, request.UserId);
            return Ok(ticket);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("{id}/start-attention")]
    [Authorize(Roles = "usuario_atencion,administrador")]
    public async Task<ActionResult<TicketDto>> StartAttention(int id, [FromBody] CallTicketRequest request)
    {
        try
        {
            var ticket = await _ticketService.StartAttentionAsync(id, request.UserId);
            return Ok(ticket);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("{id}/complete")]
    [Authorize(Roles = "usuario_atencion,administrador")]
    public async Task<ActionResult<TicketDto>> CompleteTicket(int id, [FromBody] CompleteTicketRequest request)
    {
        try
        {
            var ticket = await _ticketService.CompleteTicketAsync(id, request.UserId, request.Observacion);
            return Ok(ticket);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpPost("{id}/cancel")]
    [Authorize(Roles = "usuario_atencion,administrador")]
    public async Task<ActionResult<TicketDto>> CancelTicket(int id, [FromBody] CancelTicketRequest request)
    {
        try
        {
            var ticket = await _ticketService.CancelTicketAsync(id, request.Motivo);
            return Ok(ticket);
        }
        catch (Exception ex)
        {
            return BadRequest(new { error = ex.Message });
        }
    }

    [HttpGet("current/{userId}")]
    public async Task<ActionResult<TicketDto>> GetCurrentTicket(int userId)
    {
        var ticket = await _ticketService.GetCurrentTicketAsync(userId);
        if (ticket == null)
            return NoContent();

        return Ok(ticket);
    }

    [HttpGet("history")]
    public async Task<ActionResult> GetHistory([FromQuery] int userId, [FromQuery] DateTime fecha)
    {
        var tickets = await _ticketService.GetAttentionHistoryAsync(userId, fecha);
        return Ok(new
        {
            tickets,
            total = tickets.Count(),
            tiempoPromedio = tickets.Any()
                ? tickets.Average(t => t.TiempoAtencionSegundos ?? 0)
                : 0
        });
    }
}

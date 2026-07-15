using Ticketero.Application.DTOs;
using Ticketero.Application.Interfaces;
using Ticketero.Domain.Entities;
using Ticketero.Domain.Enums;
using Ticketero.Domain.Interfaces;

namespace Ticketero.Application.Services;

public class TicketService : ITicketService
{
    private readonly IUnitOfWork _uow;
    private readonly ITicketNotificationService _notifications;

    public TicketService(IUnitOfWork uow, ITicketNotificationService notifications)
    {
        _uow = uow;
        _notifications = notifications;
    }

    public async Task<TicketDto?> GetTicketByIdAsync(int id)
    {
        var ticket = await _uow.Tickets.GetByIdAsync(id);
        return ticket is null ? null : MapToDto(ticket);
    }

    public async Task<TicketDto> CreateTicketAsync(int areaId)
    {
        var area = await _uow.Areas.GetByIdAsync(areaId);
        if (area is null)
            throw new ArgumentException("El area especificada no existe");
        if (!area.Activo)
            throw new InvalidOperationException("El area no esta activa");

        var codigo = await _uow.Tickets.GetNextTicketCodeAsync(areaId);
        var tipo = MapTipoFromArea(area.Prefijo);

        var ticket = new Ticket
        {
            CodigoTicket = codigo,
            AreaId = areaId,
            TipoTicket = tipo,
            Status = TicketStatus.Pendiente,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _uow.Tickets.AddAsync(ticket);
        await _uow.SaveChangesAsync();

        var dto = MapToDto(ticket);
        await _notifications.NotifyTicketCreated(dto);

        var pendientes = await _uow.Tickets.GetPendingCountByAreaAsync(areaId);
        await _notifications.NotifyQueueUpdated(areaId, pendientes);

        return dto;
    }

    public async Task<IEnumerable<TicketDto>> GetPendingTicketsAsync(int areaId)
    {
        var tickets = await _uow.Tickets.GetPendingByAreaAsync(areaId);
        return tickets.Select(MapToDto);
    }

    public async Task<TicketDto> CallTicketAsync(int ticketId, int userId)
    {
        var ticket = await _uow.Tickets.GetByIdAsync(ticketId);
        if (ticket is null)
            throw new ArgumentException("Ticket no encontrado");
        if (ticket.Status != TicketStatus.Pendiente)
            throw new InvalidOperationException("El ticket no esta pendiente");

        var user = await _uow.Users.GetByIdAsync(userId);
        if (user is null)
            throw new ArgumentException("Usuario no encontrado");

        var current = await _uow.Tickets.GetCurrentByUserAsync(userId);
        if (current is not null)
            throw new InvalidOperationException("Ya tienes un ticket en atencion");

        ticket.Status = TicketStatus.Llamado;
        ticket.LlamadoPorUserId = userId;
        ticket.UpdatedAt = DateTime.UtcNow;

        await _uow.Tickets.UpdateAsync(ticket);
        await _uow.Tickets.AddAttentionLogAsync(new AttentionLog
        {
            TicketId = ticketId,
            UserId = userId,
            LlamadoAt = DateTime.UtcNow
        });
        await _uow.SaveChangesAsync();

        var dto = MapToDto(ticket);
        await _notifications.NotifyTicketCalled(dto);

        var pendientes = await _uow.Tickets.GetPendingCountByAreaAsync(ticket.AreaId);
        await _notifications.NotifyQueueUpdated(ticket.AreaId, pendientes);

        return dto;
    }

    public async Task<TicketDto> StartAttentionAsync(int ticketId, int userId)
    {
        var ticket = await _uow.Tickets.GetByIdAsync(ticketId);
        if (ticket is null)
            throw new ArgumentException("Ticket no encontrado");
        if (ticket.Status != TicketStatus.Llamado)
            throw new InvalidOperationException("El ticket debe estar en estado llamado");

        ticket.Status = TicketStatus.EnAtencion;
        ticket.UpdatedAt = DateTime.UtcNow;

        await _uow.Tickets.UpdateAsync(ticket);
        await _uow.Tickets.UpdateAttentionLogStartAsync(ticketId, userId, DateTime.UtcNow);
        await _uow.SaveChangesAsync();

        var dto = MapToDto(ticket);
        await _notifications.NotifyTicketStarted(dto);

        return dto;
    }

    public async Task<TicketDto> CompleteTicketAsync(int ticketId, int userId, string? observacion)
    {
        var ticket = await _uow.Tickets.GetByIdAsync(ticketId);
        if (ticket is null)
            throw new ArgumentException("Ticket no encontrado");
        if (ticket.Status != TicketStatus.EnAtencion)
            throw new InvalidOperationException("El ticket debe estar en atencion");

        ticket.Status = TicketStatus.Completado;
        ticket.UpdatedAt = DateTime.UtcNow;

        await _uow.Tickets.UpdateAsync(ticket);
        await _uow.Tickets.CompleteAttentionLogAsync(ticketId, userId, DateTime.UtcNow, observacion);
        await _uow.SaveChangesAsync();

        var dto = MapToDto(ticket);
        await _notifications.NotifyTicketCompleted(dto);

        return dto;
    }

    public async Task<TicketDto> CancelTicketAsync(int ticketId, string? motivo)
    {
        var ticket = await _uow.Tickets.GetByIdAsync(ticketId);
        if (ticket is null)
            throw new ArgumentException("Ticket no encontrado");
        if (ticket.Status is TicketStatus.Completado or TicketStatus.Cancelado)
            throw new InvalidOperationException("El ticket ya fue finalizado");

        ticket.Status = TicketStatus.Cancelado;
        ticket.UpdatedAt = DateTime.UtcNow;

        await _uow.Tickets.UpdateAsync(ticket);

        if (ticket.LlamadoPorUserId.HasValue)
            await _uow.Tickets.CancelAttentionLogAsync(ticketId, motivo ?? "Cancelado por operador");

        await _uow.SaveChangesAsync();

        var dto = MapToDto(ticket);
        await _notifications.NotifyTicketCancelled(dto);

        var pendientes = await _uow.Tickets.GetPendingCountByAreaAsync(ticket.AreaId);
        await _notifications.NotifyQueueUpdated(ticket.AreaId, pendientes);

        return dto;
    }

    public async Task<TicketDto?> GetCurrentTicketAsync(int userId)
    {
        var ticket = await _uow.Tickets.GetCurrentByUserAsync(userId);
        return ticket is null ? null : MapToDto(ticket);
    }

    public async Task<IEnumerable<TicketDto>> GetAttentionHistoryAsync(int userId, DateTime fecha)
    {
        var tickets = await _uow.Tickets.GetHistoryByUserAndDateAsync(userId, fecha);
        return tickets.Select(MapToDto);
    }

    private static TicketDto MapToDto(Ticket t)
    {
        int? tiempoEspera = null;
        if (t.AttentionLog?.LlamadoAt is not null)
            tiempoEspera = (int)(t.AttentionLog.LlamadoAt - t.CreatedAt).TotalSeconds;

        return new TicketDto
        {
            Id = t.Id,
            CodigoTicket = t.CodigoTicket,
            TipoTicket = t.TipoTicket.ToString(),
            AreaId = t.AreaId,
            AreaNombre = t.Area?.Nombre ?? "",
            Status = t.Status.ToString(),
            LlamadoPorUserId = t.LlamadoPorUserId,
            LlamadoPorUserName = t.LlamadoPorUser?.NombreCompleto,
            CreadoEn = t.CreatedAt,
            UpdatedAt = t.UpdatedAt,
            TiempoEsperaSegundos = tiempoEspera,
            TiempoAtencionSegundos = t.AttentionLog?.TiempoSegundos,
            TiempoAtencionFormateado = t.AttentionLog?.TiempoSegundos is null
                ? null
                : FormatSegundos(t.AttentionLog.TiempoSegundos.Value)
        };
    }

    private static string FormatSegundos(int s)
    {
        var ts = TimeSpan.FromSeconds(s);
        return ts.TotalHours >= 1
            ? $"{(int)ts.TotalHours}:{ts.Minutes:D2}:{ts.Seconds:D2}"
            : $"{ts.Minutes:D2}:{ts.Seconds:D2}";
    }

    private static TicketType MapTipoFromArea(string prefijo) => prefijo.ToUpper() switch
    {
        "CAJA" => TicketType.Caja,
        "INFO" => TicketType.Informacion,
        "INSC" => TicketType.Inscripcion,
        "DOC" => TicketType.Documentacion,
        _ => TicketType.Informacion
    };
}

using Microsoft.EntityFrameworkCore;
using Ticketero.Domain.Entities;
using Ticketero.Domain.Interfaces;
using Ticketero.Infrastructure.Data;

namespace Ticketero.Infrastructure.Repositories;

public class TicketRepository : ITicketRepository
{
    private readonly AppDbContext _context;

    public TicketRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Ticket> GetByIdAsync(int id)
    {
        return await _context.Tickets
            .Include(t => t.Area)
            .Include(t => t.LlamadoPorUser)
            .Include(t => t.AttentionLog)
            .FirstOrDefaultAsync(t => t.Id == id)
            ?? throw new KeyNotFoundException($"Ticket {id} no encontrado");
    }

    public async Task<IEnumerable<Ticket>> GetPendingByAreaAsync(int areaId)
    {
        return await _context.Tickets
            .Where(t => t.AreaId == areaId && t.Status == Domain.Enums.TicketStatus.Pendiente)
            .OrderBy(t => t.CreatedAt)
            .Include(t => t.Area)
            .ToListAsync();
    }

    public async Task<Ticket?> GetCurrentByUserAsync(int userId)
    {
        return await _context.Tickets
            .Where(t => t.LlamadoPorUserId == userId
                && (t.Status == Domain.Enums.TicketStatus.Llamado
                    || t.Status == Domain.Enums.TicketStatus.EnAtencion))
            .Include(t => t.Area)
            .Include(t => t.AttentionLog)
            .FirstOrDefaultAsync();
    }

    public async Task<IEnumerable<Ticket>> GetHistoryByUserAndDateAsync(int userId, DateTime fecha)
    {
        return await _context.Tickets
            .Where(t => t.LlamadoPorUserId == userId
                && t.CreatedAt.Date == fecha.Date
                && (t.Status == Domain.Enums.TicketStatus.Completado
                    || t.Status == Domain.Enums.TicketStatus.Cancelado))
            .OrderByDescending(t => t.CreatedAt)
            .Include(t => t.Area)
            .Include(t => t.AttentionLog)
            .ToListAsync();
    }

    public async Task<IEnumerable<Ticket>> GetAllInRangeAsync(DateTime inicio, DateTime fin)
    {
        return await _context.Tickets
            .Where(t => t.CreatedAt >= inicio && t.CreatedAt <= fin)
            .Include(t => t.Area)
            .Include(t => t.LlamadoPorUser)
                .ThenInclude(u => u!.Area)
            .Include(t => t.AttentionLog)
            .ToListAsync();
    }

    public async Task<Ticket> AddAsync(Ticket ticket)
    {
        _context.Tickets.Add(ticket);
        await Task.CompletedTask;
        return ticket;
    }

    public async Task UpdateAsync(Ticket ticket)
    {
        _context.Entry(ticket).State = EntityState.Modified;
        await Task.CompletedTask;
    }

    public async Task<string> GetNextTicketCodeAsync(int areaId)
    {
        var area = await _context.Areas.FindAsync(areaId)
            ?? throw new ArgumentException("Area no encontrada");

        var hoy = DateTime.UtcNow.Date;
        var ultimoCodigo = await _context.Tickets
            .Where(t => t.AreaId == areaId && t.CreatedAt.Date == hoy)
            .OrderByDescending(t => t.CreatedAt)
            .Select(t => t.CodigoTicket)
            .FirstOrDefaultAsync();

        int secuencia = 1;
        if (ultimoCodigo is not null && ultimoCodigo.Contains('-'))
        {
            var partes = ultimoCodigo.Split('-');
            if (partes.Length == 2 && int.TryParse(partes[1], out var num))
                secuencia = num + 1;
        }

        return $"{area.Prefijo}-{secuencia:D4}";
    }

    public async Task<int> GetPendingCountByAreaAsync(int areaId)
    {
        return await _context.Tickets
            .CountAsync(t => t.AreaId == areaId && t.Status == Domain.Enums.TicketStatus.Pendiente);
    }

    public async Task AddAttentionLogAsync(AttentionLog log)
    {
        _context.AttentionLogs.Add(log);
        await Task.CompletedTask;
    }

    public async Task UpdateAttentionLogStartAsync(int ticketId, int userId, DateTime iniciadoAt)
    {
        var log = await _context.AttentionLogs
            .FirstOrDefaultAsync(l => l.TicketId == ticketId && l.UserId == userId);
        if (log is not null)
        {
            log.IniciadoAt = iniciadoAt;
            _context.Entry(log).State = EntityState.Modified;
        }
    }

    public async Task CompleteAttentionLogAsync(int ticketId, int userId, DateTime completadoAt, string? observacion)
    {
        var log = await _context.AttentionLogs
            .FirstOrDefaultAsync(l => l.TicketId == ticketId && l.UserId == userId);
        if (log is not null)
        {
            log.CompletadoAt = completadoAt;
            if (log.IniciadoAt.HasValue)
                log.TiempoSegundos = (int)(completadoAt - log.IniciadoAt.Value).TotalSeconds;
            log.Observacion = observacion;
            _context.Entry(log).State = EntityState.Modified;
        }
    }

    public async Task CancelAttentionLogAsync(int ticketId, string motivo)
    {
        var log = await _context.AttentionLogs
            .FirstOrDefaultAsync(l => l.TicketId == ticketId);
        if (log is not null)
        {
            log.CompletadoAt = DateTime.UtcNow;
            log.Observacion = motivo;
            _context.Entry(log).State = EntityState.Modified;
        }
    }
}

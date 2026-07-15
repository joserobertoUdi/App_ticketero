using Microsoft.EntityFrameworkCore;
using Ticketero.Domain.Entities;
using Ticketero.Domain.Interfaces;
using Ticketero.Infrastructure.Data;

namespace Ticketero.Infrastructure.Repositories;

public class AreaRepository : IAreaRepository
{
    private readonly AppDbContext _context;

    public AreaRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<Area?> GetByIdAsync(int id)
    {
        return await _context.Areas.FindAsync(id);
    }

    public async Task<IEnumerable<Area>> GetAllActiveAsync()
    {
        return await _context.Areas
            .Where(a => a.Activo)
            .OrderBy(a => a.Nombre)
            .ToListAsync();
    }

    public async Task<Area> AddAsync(Area area)
    {
        _context.Areas.Add(area);
        await Task.CompletedTask;
        return area;
    }

    public async Task UpdateAsync(Area area)
    {
        _context.Entry(area).State = EntityState.Modified;
        await Task.CompletedTask;
    }
}

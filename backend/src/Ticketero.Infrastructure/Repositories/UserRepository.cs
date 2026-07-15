using Microsoft.EntityFrameworkCore;
using Ticketero.Domain.Entities;
using Ticketero.Domain.Interfaces;
using Ticketero.Infrastructure.Data;

namespace Ticketero.Infrastructure.Repositories;

public class UserRepository : IUserRepository
{
    private readonly AppDbContext _context;

    public UserRepository(AppDbContext context)
    {
        _context = context;
    }

    public async Task<User?> GetByIdAsync(int id)
    {
        return await _context.Users
            .Include(u => u.Area)
            .FirstOrDefaultAsync(u => u.Id == id);
    }

    public async Task<User?> GetByNombreUsuarioAsync(string nombreUsuario)
    {
        return await _context.Users
            .Include(u => u.Area)
            .FirstOrDefaultAsync(u => u.NombreUsuario == nombreUsuario);
    }

    public async Task<IEnumerable<User>> GetAllAsync()
    {
        return await _context.Users
            .Include(u => u.Area)
            .OrderBy(u => u.NombreCompleto)
            .ToListAsync();
    }

    public async Task<IEnumerable<User>> GetByAreaAsync(int areaId)
    {
        return await _context.Users
            .Where(u => u.AreaId == areaId && u.Activo)
            .Include(u => u.Area)
            .ToListAsync();
    }

    public async Task<User> AddAsync(User user)
    {
        _context.Users.Add(user);
        await Task.CompletedTask;
        return user;
    }

    public async Task UpdateAsync(User user)
    {
        _context.Entry(user).State = EntityState.Modified;
        await Task.CompletedTask;
    }
}

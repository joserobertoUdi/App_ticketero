using Ticketero.Domain.Entities;

namespace Ticketero.Domain.Interfaces;

public interface IUserRepository
{
    Task<User?> GetByIdAsync(int id);
    Task<User?> GetByNombreUsuarioAsync(string nombreUsuario);
    Task<IEnumerable<User>> GetAllAsync();
    Task<IEnumerable<User>> GetByAreaAsync(int areaId);
    Task<User> AddAsync(User user);
    Task UpdateAsync(User user);
}

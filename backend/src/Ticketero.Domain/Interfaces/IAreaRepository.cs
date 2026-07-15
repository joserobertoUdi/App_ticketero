using Ticketero.Domain.Entities;

namespace Ticketero.Domain.Interfaces;

public interface IAreaRepository
{
    Task<Area?> GetByIdAsync(int id);
    Task<IEnumerable<Area>> GetAllActiveAsync();
    Task<Area> AddAsync(Area area);
    Task UpdateAsync(Area area);
}

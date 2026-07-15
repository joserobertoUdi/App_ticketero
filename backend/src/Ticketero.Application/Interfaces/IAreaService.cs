using Ticketero.Application.DTOs;

namespace Ticketero.Application.Interfaces;

public interface IAreaService
{
    Task<IEnumerable<AreaDto>> GetAllActiveAsync();
    Task<AreaDto> CreateAsync(CreateAreaRequest request);
    Task<AreaDto> UpdateAsync(int id, UpdateAreaRequest request);
}

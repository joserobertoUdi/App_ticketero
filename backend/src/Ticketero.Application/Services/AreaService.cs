using Ticketero.Application.DTOs;
using Ticketero.Application.Interfaces;
using Ticketero.Domain.Entities;
using Ticketero.Domain.Interfaces;

namespace Ticketero.Application.Services;

public class AreaService : IAreaService
{
    private readonly IUnitOfWork _uow;

    public AreaService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<IEnumerable<AreaDto>> GetAllActiveAsync()
    {
        var areas = await _uow.Areas.GetAllActiveAsync();
        return areas.Select(a => new AreaDto
        {
            Id = a.Id,
            Nombre = a.Nombre,
            Prefijo = a.Prefijo,
            Activo = a.Activo
        });
    }

    public async Task<AreaDto> CreateAsync(CreateAreaRequest request)
    {
        var area = new Area
        {
            Nombre = request.Nombre,
            Prefijo = request.Prefijo.ToUpper(),
            Activo = request.Activo,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };

        await _uow.Areas.AddAsync(area);
        await _uow.SaveChangesAsync();

        return new AreaDto
        {
            Id = area.Id,
            Nombre = area.Nombre,
            Prefijo = area.Prefijo,
            Activo = area.Activo
        };
    }

    public async Task<AreaDto> UpdateAsync(int id, UpdateAreaRequest request)
    {
        var area = await _uow.Areas.GetByIdAsync(id)
            ?? throw new ArgumentException("Area no encontrada");

        if (request.Nombre is not null)
            area.Nombre = request.Nombre;
        if (request.Prefijo is not null)
            area.Prefijo = request.Prefijo.ToUpper();
        if (request.Activo.HasValue)
            area.Activo = request.Activo.Value;
        area.UpdatedAt = DateTime.UtcNow;

        await _uow.Areas.UpdateAsync(area);
        await _uow.SaveChangesAsync();

        return new AreaDto
        {
            Id = area.Id,
            Nombre = area.Nombre,
            Prefijo = area.Prefijo,
            Activo = area.Activo
        };
    }
}

using Ticketero.Application.DTOs;
using Ticketero.Application.Interfaces;
using Ticketero.Domain.Entities;
using Ticketero.Domain.Enums;
using Ticketero.Domain.Interfaces;

namespace Ticketero.Application.Services;

public class UserService : IUserService
{
    private readonly IUnitOfWork _uow;

    public UserService(IUnitOfWork uow)
    {
        _uow = uow;
    }

    public async Task<IEnumerable<UserDto>> GetAllAsync()
    {
        var users = await _uow.Users.GetAllAsync();
        return users.Select(u => new UserDto
        {
            Id = u.Id,
            NombreUsuario = u.NombreUsuario,
            NombreCompleto = u.NombreCompleto,
            Rol = u.Rol.ToString(),
            AreaId = u.AreaId,
            AreaNombre = u.Area?.Nombre,
            Activo = u.Activo,
            UltimoAcceso = u.UltimoAcceso
        });
    }

    public async Task<UserDto> CreateAsync(CreateUserRequest request)
    {
        if (!Enum.TryParse<UserRole>(request.Rol, true, out var rol))
            throw new ArgumentException("Rol invalido");

        if (request.AreaId.HasValue)
        {
            var area = await _uow.Areas.GetByIdAsync(request.AreaId.Value);
            if (area is null)
                throw new ArgumentException("Area no encontrada");
        }

        var user = new User
        {
            NombreUsuario = request.NombreUsuario,
            NombreCompleto = request.NombreCompleto,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Rol = rol,
            AreaId = request.AreaId,
            Activo = true,
            CreatedAt = DateTime.UtcNow
        };

        await _uow.Users.AddAsync(user);
        await _uow.SaveChangesAsync();

        return new UserDto
        {
            Id = user.Id,
            NombreUsuario = user.NombreUsuario,
            NombreCompleto = user.NombreCompleto,
            Rol = user.Rol.ToString(),
            AreaId = user.AreaId,
            AreaNombre = user.Area?.Nombre,
            Activo = user.Activo
        };
    }

    public async Task<UserDto> UpdateAsync(int id, UpdateUserRequest request)
    {
        var user = await _uow.Users.GetByIdAsync(id)
            ?? throw new ArgumentException("Usuario no encontrado");

        if (request.NombreCompleto is not null)
            user.NombreCompleto = request.NombreCompleto;
        if (request.Activo.HasValue)
            user.Activo = request.Activo.Value;
        if (request.AreaId.HasValue)
        {
            if (request.AreaId.Value == 0)
                user.AreaId = null;
            else
            {
                var area = await _uow.Areas.GetByIdAsync(request.AreaId.Value);
                if (area is null)
                    throw new ArgumentException("Area no encontrada");
                user.AreaId = request.AreaId.Value;
            }
        }

        await _uow.Users.UpdateAsync(user);
        await _uow.SaveChangesAsync();

        return new UserDto
        {
            Id = user.Id,
            NombreUsuario = user.NombreUsuario,
            NombreCompleto = user.NombreCompleto,
            Rol = user.Rol.ToString(),
            AreaId = user.AreaId,
            AreaNombre = user.Area?.Nombre,
            Activo = user.Activo,
            UltimoAcceso = user.UltimoAcceso
        };
    }

    public async Task DeleteAsync(int id)
    {
        var user = await _uow.Users.GetByIdAsync(id)
            ?? throw new ArgumentException("Usuario no encontrado");

        user.Activo = false;
        await _uow.Users.UpdateAsync(user);
        await _uow.SaveChangesAsync();
    }
}

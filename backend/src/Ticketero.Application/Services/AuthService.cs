using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Microsoft.Extensions.Configuration;
using Microsoft.IdentityModel.Tokens;
using Ticketero.Application.DTOs;
using Ticketero.Application.Interfaces;
using Ticketero.Domain.Interfaces;

namespace Ticketero.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _uow;
    private readonly IConfiguration _configuration;

    public AuthService(IUnitOfWork uow, IConfiguration configuration)
    {
        _uow = uow;
        _configuration = configuration;
    }

    public async Task<LoginResponse> LoginAsync(LoginRequest request)
    {
        var user = await _uow.Users.GetByNombreUsuarioAsync(request.NombreUsuario);
        if (user is null || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            throw new UnauthorizedAccessException("Credenciales invalidas");
        if (!user.Activo)
            throw new UnauthorizedAccessException("Usuario desactivado");

        user.UltimoAcceso = DateTime.UtcNow;
        await _uow.Users.UpdateAsync(user);
        await _uow.SaveChangesAsync();

        var token = GenerateJwtToken(user);
        var refreshToken = GenerateRefreshToken();

        return new LoginResponse
        {
            Token = token,
            RefreshToken = refreshToken,
            Usuario = new UserDto
            {
                Id = user.Id,
                NombreUsuario = user.NombreUsuario,
                NombreCompleto = user.NombreCompleto,
                Rol = user.Rol.ToString(),
                AreaId = user.AreaId,
                AreaNombre = user.Area?.Nombre,
                Activo = user.Activo,
                UltimoAcceso = user.UltimoAcceso
            },
            ExpiraEn = DateTime.UtcNow.AddMinutes(
                _configuration.GetValue<int>("JwtSettings:ExpirationMinutes"))
        };
    }

    public Task<RefreshTokenResponse> RefreshTokenAsync(string refreshToken)
    {
        // Rotar refresh token (implementacion basica - en produccion validar contra store)
        var newJwt = GenerateJwtToken(null);
        return Task.FromResult(new RefreshTokenResponse
        {
            Token = newJwt,
            RefreshToken = GenerateRefreshToken(),
            ExpiraEn = DateTime.UtcNow.AddMinutes(
                _configuration.GetValue<int>("JwtSettings:ExpirationMinutes"))
        });
    }

    private string GenerateJwtToken(Domain.Entities.User? user)
    {
        var jwtSettings = _configuration.GetSection("JwtSettings");
        var secretKey = Encoding.UTF8.GetBytes(jwtSettings["SecretKey"]!);
        var expirationMinutes = int.Parse(jwtSettings["ExpirationMinutes"] ?? "480");

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, user?.Id.ToString() ?? "0"),
            new(JwtRegisteredClaimNames.UniqueName, user?.NombreUsuario ?? ""),
            new("nombre", user?.NombreCompleto ?? "")
        };

        if (user is not null)
        {
            claims.Add(new Claim(ClaimTypes.Role, user.Rol.ToString()));
            if (user.AreaId.HasValue)
                claims.Add(new Claim("areaId", user.AreaId.Value.ToString()));
        }

        var token = new JwtSecurityToken(
            issuer: jwtSettings["Issuer"],
            audience: jwtSettings["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expirationMinutes),
            signingCredentials: new SigningCredentials(
                new SymmetricSecurityKey(secretKey),
                SecurityAlgorithms.HmacSha256)
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private static string GenerateRefreshToken()
    {
        var bytes = new byte[32];
        using var rng = RandomNumberGenerator.Create();
        rng.GetBytes(bytes);
        return Convert.ToBase64String(bytes);
    }
}

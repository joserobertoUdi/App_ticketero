using Ticketero.Application.DTOs;

namespace Ticketero.Application.Interfaces;

public interface IAuthService
{
    Task<LoginResponse> LoginAsync(LoginRequest request);
    Task<RefreshTokenResponse> RefreshTokenAsync(string refreshToken);
}

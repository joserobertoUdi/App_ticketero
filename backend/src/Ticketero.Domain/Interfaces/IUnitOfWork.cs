namespace Ticketero.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    ITicketRepository Tickets { get; }
    IUserRepository Users { get; }
    IAreaRepository Areas { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
    Task BeginTransactionAsync();
    Task CommitTransactionAsync();
    Task RollbackTransactionAsync();
}

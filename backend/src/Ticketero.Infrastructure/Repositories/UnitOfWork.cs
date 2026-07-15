using Microsoft.EntityFrameworkCore.Storage;
using Ticketero.Domain.Interfaces;
using Ticketero.Infrastructure.Data;

namespace Ticketero.Infrastructure.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly AppDbContext _context;
    private IDbContextTransaction? _transaction;
    private ITicketRepository? _tickets;
    private IUserRepository? _users;
    private IAreaRepository? _areas;

    public UnitOfWork(AppDbContext context)
    {
        _context = context;
    }

    public ITicketRepository Tickets =>
        _tickets ??= new TicketRepository(_context);

    public IUserRepository Users =>
        _users ??= new UserRepository(_context);

    public IAreaRepository Areas =>
        _areas ??= new AreaRepository(_context);

    public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
    {
        return await _context.SaveChangesAsync(cancellationToken);
    }

    public async Task BeginTransactionAsync()
    {
        _transaction = await _context.Database.BeginTransactionAsync();
    }

    public async Task CommitTransactionAsync()
    {
        if (_transaction is not null)
            await _transaction.CommitAsync();
    }

    public async Task RollbackTransactionAsync()
    {
        if (_transaction is not null)
            await _transaction.RollbackAsync();
    }

    public void Dispose()
    {
        _transaction?.Dispose();
        _context.Dispose();
    }
}

using Microsoft.EntityFrameworkCore;
using Ticketero.Domain.Entities;
using Ticketero.Domain.Enums;

namespace Ticketero.Infrastructure.Data;

public class AppDbContext : DbContext
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Area> Areas => Set<Area>();
    public DbSet<User> Users => Set<User>();
    public DbSet<Ticket> Tickets => Set<Ticket>();
    public DbSet<AttentionLog> AttentionLogs => Set<AttentionLog>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        // Area
        modelBuilder.Entity<Area>(entity =>
        {
            entity.ToTable("Areas");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Nombre).HasMaxLength(100).IsRequired();
            entity.Property(e => e.Prefijo).HasMaxLength(10).IsRequired();
            entity.HasIndex(e => e.Nombre).IsUnique();
            entity.HasIndex(e => e.Prefijo).IsUnique();
        });

        // User
        modelBuilder.Entity<User>(entity =>
        {
            entity.ToTable("Users");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.NombreUsuario).HasMaxLength(50).IsRequired();
            entity.Property(e => e.NombreCompleto).HasMaxLength(150).IsRequired();
            entity.Property(e => e.PasswordHash).HasMaxLength(255).IsRequired();
            entity.Property(e => e.Rol)
                .HasMaxLength(20)
                .HasConversion(v => v.ToString(), v => (UserRole)Enum.Parse(typeof(UserRole), v));
            entity.HasIndex(e => e.NombreUsuario).IsUnique();
            entity.HasOne(e => e.Area)
                .WithMany(a => a.Users)
                .HasForeignKey(e => e.AreaId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // Ticket
        modelBuilder.Entity<Ticket>(entity =>
        {
            entity.ToTable("Tickets");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.CodigoTicket).HasMaxLength(20).IsRequired();
            entity.Property(e => e.TipoTicket)
                .HasMaxLength(20)
                .HasConversion(v => v.ToString(), v => (TicketType)Enum.Parse(typeof(TicketType), v));
            entity.Property(e => e.Status)
                .HasMaxLength(20)
                .HasConversion(v => v.ToString(), v => (TicketStatus)Enum.Parse(typeof(TicketStatus), v));
            entity.HasIndex(e => e.CodigoTicket).IsUnique();
            entity.HasOne(e => e.Area)
                .WithMany(a => a.Tickets)
                .HasForeignKey(e => e.AreaId);
            entity.HasOne(e => e.LlamadoPorUser)
                .WithMany(u => u.LlamadosTickets)
                .HasForeignKey(e => e.LlamadoPorUserId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        // AttentionLog
        modelBuilder.Entity<AttentionLog>(entity =>
        {
            entity.ToTable("AttentionLogs");
            entity.HasKey(e => e.Id);
            entity.HasOne(e => e.Ticket)
                .WithOne(t => t.AttentionLog)
                .HasForeignKey<AttentionLog>(e => e.TicketId);
            entity.HasOne(e => e.User)
                .WithMany(u => u.AttentionLogs)
                .HasForeignKey(e => e.UserId);
            entity.HasIndex(e => new { e.UserId, e.LlamadoAt });
        });
    }
}

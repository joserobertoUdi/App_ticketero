-- ============================================================
-- SCRIPT 003: Índices para optimización de consultas
-- ============================================================
USE TicketeroDB;
GO

-- Tickets: Búsqueda por status (más frecuente)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Tickets_Status')
    CREATE NONCLUSTERED INDEX [IX_Tickets_Status] ON [dbo].[Tickets] ([Status])
    INCLUDE ([CodigoTicket], [AreaId], [CreatedAt]);
GO

-- Tickets: Búsqueda por área + status (cola de espera)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Tickets_AreaId_Status')
    CREATE NONCLUSTERED INDEX [IX_Tickets_AreaId_Status] ON [dbo].[Tickets] ([AreaId], [Status])
    INCLUDE ([CodigoTicket], [CreatedAt]);
GO

-- Tickets: Búsqueda por fecha (dashboard)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Tickets_CreatedAt')
    CREATE NONCLUSTERED INDEX [IX_Tickets_CreatedAt] ON [dbo].[Tickets] ([CreatedAt])
    INCLUDE ([Status], [AreaId]);
GO

-- Tickets: Único por día para código secuencial
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Tickets_CodigoArea_Fecha')
    CREATE NONCLUSTERED INDEX [IX_Tickets_CodigoArea_Fecha] ON [dbo].[Tickets] ([AreaId], CAST([CreatedAt] AS DATE))
    INCLUDE ([CodigoTicket]);
GO

-- AttentionLogs: Búsqueda por usuario + fecha (historial agente)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AttentionLogs_UserId_Fecha')
    CREATE NONCLUSTERED INDEX [IX_AttentionLogs_UserId_Fecha] ON [dbo].[AttentionLogs] ([UserId], CAST([LlamadoAt] AS DATE))
    INCLUDE ([TicketId], [TiempoSegundos]);
GO

-- AttentionLogs: Búsqueda por fecha (dashboard)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_AttentionLogs_LlamadoAt')
    CREATE NONCLUSTERED INDEX [IX_AttentionLogs_LlamadoAt] ON [dbo].[AttentionLogs] ([LlamadoAt])
    INCLUDE ([UserId], [TiempoSegundos]);
GO

-- Users: Búsqueda por nombre de usuario (login)
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_Users_NombreUsuario')
    CREATE NONCLUSTERED INDEX [IX_Users_NombreUsuario] ON [dbo].[Users] ([NombreUsuario])
    INCLUDE ([PasswordHash], [Rol], [AreaId], [Activo]);
GO

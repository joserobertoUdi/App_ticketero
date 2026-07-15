-- ============================================================
-- SCRIPT 002: Creación de tablas del sistema Ticketero
-- ============================================================
USE TicketeroDB;
GO

-- ============================================================
-- Tabla: Areas
-- Propósito: Almacena las áreas de atención disponibles
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Areas]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[Areas] (
        [Id]            INT             IDENTITY(1,1)   NOT NULL,
        [Nombre]        NVARCHAR(100)   NOT NULL,
        [Prefijo]       NVARCHAR(10)    NOT NULL,
        [Activo]        BIT             NOT NULL        DEFAULT 1,
        [CreatedAt]     DATETIME2       NOT NULL        DEFAULT GETUTCDATE(),
        [UpdatedAt]     DATETIME2       NOT NULL        DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_Areas] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Areas_Nombre] UNIQUE ([Nombre]),
        CONSTRAINT [UQ_Areas_Prefijo] UNIQUE ([Prefijo])
    );
END
GO

-- ============================================================
-- Tabla: Users
-- Propósito: Almacena usuarios del sistema (admins y agentes)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Users]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[Users] (
        [Id]                INT             IDENTITY(1,1)   NOT NULL,
        [NombreUsuario]     NVARCHAR(50)    NOT NULL,
        [NombreCompleto]    NVARCHAR(150)   NOT NULL,
        [PasswordHash]      NVARCHAR(255)   NOT NULL,
        [Rol]               NVARCHAR(20)    NOT NULL,
        [AreaId]            INT             NULL,
        [Activo]            BIT             NOT NULL        DEFAULT 1,
        [UltimoAcceso]      DATETIME2       NULL,
        [CreatedAt]         DATETIME2       NOT NULL        DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_Users] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Users_NombreUsuario] UNIQUE ([NombreUsuario]),
        CONSTRAINT [CK_Users_Rol] CHECK ([Rol] IN ('administrador', 'usuario_atencion')),
        CONSTRAINT [FK_Users_Area] FOREIGN KEY ([AreaId]) REFERENCES [dbo].[Areas]([Id])
    );
END
GO

-- ============================================================
-- Tabla: Tickets
-- Propósito: Almacena tickets generados por los clientes
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Tickets]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[Tickets] (
        [Id]                INT             IDENTITY(1,1)   NOT NULL,
        [CodigoTicket]      NVARCHAR(20)    NOT NULL,
        [TipoTicket]        NVARCHAR(20)    NOT NULL,
        [AreaId]            INT             NOT NULL,
        [Status]            NVARCHAR(20)    NOT NULL        DEFAULT 'pendiente',
        [LlamadoPorUserId]  INT             NULL,
        [CreatedAt]         DATETIME2       NOT NULL        DEFAULT GETUTCDATE(),
        [UpdatedAt]         DATETIME2       NOT NULL        DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_Tickets] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Tickets_CodigoTicket] UNIQUE ([CodigoTicket]),
        CONSTRAINT [CK_Tickets_Status] CHECK ([Status] IN ('pendiente', 'llamado', 'en_atencion', 'completado', 'cancelado')),
        CONSTRAINT [CK_Tickets_TipoTicket] CHECK ([TipoTicket] IN ('caja', 'informacion', 'inscripcion', 'documentacion')),
        CONSTRAINT [FK_Tickets_Area] FOREIGN KEY ([AreaId]) REFERENCES [dbo].[Areas]([Id]),
        CONSTRAINT [FK_Tickets_LlamadoPor] FOREIGN KEY ([LlamadoPorUserId]) REFERENCES [dbo].[Users]([Id])
    );
END
GO

-- ============================================================
-- Tabla: AttentionLogs
-- Propósito: Registro detallado de cada atención (control de tiempos)
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[AttentionLogs]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[AttentionLogs] (
        [Id]                INT             IDENTITY(1,1)   NOT NULL,
        [TicketId]          INT             NOT NULL,
        [UserId]            INT             NOT NULL,
        [LlamadoAt]         DATETIME2       NOT NULL,
        [IniciadoAt]        DATETIME2       NULL,
        [CompletadoAt]      DATETIME2       NULL,
        [TiempoSegundos]    INT             NULL,
        [Observacion]       NVARCHAR(500)   NULL,

        CONSTRAINT [PK_AttentionLogs] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_AttentionLogs_Ticket] FOREIGN KEY ([TicketId]) REFERENCES [dbo].[Tickets]([Id]),
        CONSTRAINT [FK_AttentionLogs_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[Users]([Id]),
        CONSTRAINT [UQ_AttentionLogs_Ticket] UNIQUE ([TicketId])
    );
END
GO

-- ============================================================
-- Tabla: Configurations
-- Propósito: Almacena configuraciones clave/valor del sistema
-- ============================================================
IF NOT EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Configurations]') AND type = 'U')
BEGIN
    CREATE TABLE [dbo].[Configurations] (
        [Id]            INT             IDENTITY(1,1)   NOT NULL,
        [Clave]         NVARCHAR(100)   NOT NULL,
        [Valor]         NVARCHAR(MAX)   NOT NULL,
        [Tipo]          NVARCHAR(50)    NOT NULL        DEFAULT 'string',
        [UpdatedAt]     DATETIME2       NOT NULL        DEFAULT GETUTCDATE(),

        CONSTRAINT [PK_Configurations] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_Configurations_Clave] UNIQUE ([Clave])
    );
END
GO

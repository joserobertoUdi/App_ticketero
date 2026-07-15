-- ============================================================
-- SCRIPT 005: Stored Procedures para Dashboard y Reportes
-- ============================================================
USE TicketeroDB;
GO

-- ============================================================
-- SP_GetDashboardSummary: Resumen general de métricas
-- ============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_GetDashboardSummary')
    DROP PROCEDURE [dbo].[SP_GetDashboardSummary]
GO

CREATE PROCEDURE [dbo].[SP_GetDashboardSummary]
    @FechaInicio DATETIME2,
    @FechaFin    DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        COUNT(t.Id)                                                     AS TotalTickets,
        SUM(CASE WHEN t.Status = 'completado' THEN 1 ELSE 0 END)        AS TotalAtendidos,
        SUM(CASE WHEN t.Status IN ('pendiente', 'llamado') THEN 1 ELSE 0 END) AS TotalPendientes,
        ISNULL(AVG(al.TiempoSegundos), 0)                               AS TiempoPromedioAtencionSegundos,
        ISNULL(AVG(DATEDIFF(SECOND, t.CreatedAt, al.LlamadoAt)), 0)     AS TiempoPromedioEsperaSegundos
    FROM [dbo].[Tickets] t
    LEFT JOIN [dbo].[AttentionLogs] al ON al.TicketId = t.Id
    WHERE t.CreatedAt BETWEEN @FechaInicio AND @FechaFin;
END
GO

-- ============================================================
-- SP_GetDashboardByArea: Tickets agrupados por área
-- ============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_GetDashboardByArea')
    DROP PROCEDURE [dbo].[SP_GetDashboardByArea]
GO

CREATE PROCEDURE [dbo].[SP_GetDashboardByArea]
    @FechaInicio DATETIME2,
    @FechaFin    DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        a.Nombre                                                        AS Area,
        COUNT(t.Id)                                                     AS Total,
        SUM(CASE WHEN t.Status = 'completado' THEN 1 ELSE 0 END)        AS Atendidos,
        SUM(CASE WHEN t.Status IN ('pendiente', 'llamado') THEN 1 ELSE 0 END) AS Pendientes,
        ISNULL(AVG(al.TiempoSegundos), 0)                               AS TiempoPromedioSegundos
    FROM [dbo].[Areas] a
    LEFT JOIN [dbo].[Tickets] t ON t.AreaId = a.Id AND t.CreatedAt BETWEEN @FechaInicio AND @FechaFin
    LEFT JOIN [dbo].[AttentionLogs] al ON al.TicketId = t.Id
    WHERE a.Activo = 1
    GROUP BY a.Nombre, a.Id
    ORDER BY Total DESC;
END
GO

-- ============================================================
-- SP_GetDashboardByUser: Rendimiento por usuario/agente
-- ============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_GetDashboardByUser')
    DROP PROCEDURE [dbo].[SP_GetDashboardByUser]
GO

CREATE PROCEDURE [dbo].[SP_GetDashboardByUser]
    @FechaInicio DATETIME2,
    @FechaFin    DATETIME2
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        u.NombreCompleto                                                AS Nombre,
        COUNT(al.Id)                                                    AS TotalAtendidos,
        ISNULL(AVG(al.TiempoSegundos), 0)                               AS TiempoPromedioSegundos,
        a.Nombre                                                        AS Area
    FROM [dbo].[Users] u
    INNER JOIN [dbo].[AttentionLogs] al ON al.UserId = u.Id
    INNER JOIN [dbo].[Tickets] t ON t.Id = al.TicketId
    LEFT JOIN [dbo].[Areas] a ON a.Id = u.AreaId
    WHERE t.CreatedAt BETWEEN @FechaInicio AND @FechaFin
    GROUP BY u.NombreCompleto, a.Nombre
    ORDER BY TotalAtendidos DESC;
END
GO

-- ============================================================
-- SP_GetHourlyBreakdown: Desglose horario de atenciones
-- ============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_GetHourlyBreakdown')
    DROP PROCEDURE [dbo].[SP_GetHourlyBreakdown]
GO

CREATE PROCEDURE [dbo].[SP_GetHourlyBreakdown]
    @Fecha DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        DATEPART(HOUR, t.CreatedAt)                                     AS Hora,
        COUNT(t.Id)                                                     AS Total
    FROM [dbo].[Tickets] t
    WHERE CAST(t.CreatedAt AS DATE) = @Fecha
    GROUP BY DATEPART(HOUR, t.CreatedAt)
    ORDER BY Hora;
END
GO

-- ============================================================
-- SP_GetNextTicketSequence: Obtener siguiente número secuencial
-- ============================================================
IF EXISTS (SELECT * FROM sys.objects WHERE type = 'P' AND name = 'SP_GetNextTicketSequence')
    DROP PROCEDURE [dbo].[SP_GetNextTicketSequence]
GO

CREATE PROCEDURE [dbo].[SP_GetNextTicketSequence]
    @AreaId INT,
    @Codigo NVARCHAR(20) OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @Prefijo NVARCHAR(10);
    DECLARE @Fecha DATE = CAST(GETUTCDATE() AS DATE);
    DECLARE @Secuencia INT;

    SELECT @Prefijo = Prefijo FROM [dbo].[Areas] WHERE Id = @AreaId;

    SELECT @Secuencia = ISNULL(MAX(CAST(SUBSTRING(CodigoTicket, LEN(@Prefijo) + 2, 4) AS INT)), 0) + 1
    FROM [dbo].[Tickets]
    WHERE CodigoTicket LIKE @Prefijo + '-%'
      AND CAST(CreatedAt AS DATE) = @Fecha;

    IF @Secuencia IS NULL
        SET @Secuencia = 1;

    SET @Codigo = @Prefijo + '-' + RIGHT('0000' + CAST(@Secuencia AS NVARCHAR(4)), 4);
END
GO

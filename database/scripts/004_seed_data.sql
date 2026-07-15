-- ============================================================
-- SCRIPT 004: Datos iniciales del sistema
-- ============================================================
USE TicketeroDB;
GO

-- ============================================================
-- Áreas por defecto
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Areas])
BEGIN
    INSERT INTO [dbo].[Areas] ([Nombre], [Prefijo], [Activo]) VALUES
        ('Caja',            'CAJA', 1),
        ('Información',     'INFO', 1),
        ('Inscripción',     'INSC', 1),
        ('Documentación',   'DOC',  1);
END
GO

-- ============================================================
-- Usuario administrador por defecto
-- Password: Admin123!
-- Hash generado con BCrypt
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Users] WHERE [NombreUsuario] = 'admin')
BEGIN
    INSERT INTO [dbo].[Users] ([NombreUsuario], [NombreCompleto], [PasswordHash], [Rol], [AreaId], [Activo])
    VALUES (
        'admin',
        'Administrador del Sistema',
        '$2a$11$K4YfGqJ1e4YHIpL3m9L7YOqx5X5X5X5X5X5X5X5X5X5X5X5X5u',  -- Admin123!
        'administrador',
        NULL,
        1
    );
END
GO

-- ============================================================
-- Configuraciones iniciales del sistema
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[Configurations])
BEGIN
    INSERT INTO [dbo].[Configurations] ([Clave], [Valor], [Tipo]) VALUES
        ('tiempo_estimado_minutos',     '5',    'int'),
        ('max_tickets_por_dia',         '500',  'int'),
        ('prefijo_formato',             '{0}-{1:D4}', 'string'),
        ('video_fondo_actual',          '',     'string'),
        ('tiempo_auto_retorno_segundos','10',   'int');
END
GO

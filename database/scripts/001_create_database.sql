-- ============================================================
-- SCRIPT 001: Creación de la base de datos TicketeroDB
-- ============================================================

IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'TicketeroDB')
BEGIN
    CREATE DATABASE TicketeroDB;
END
GO

USE TicketeroDB;
GO

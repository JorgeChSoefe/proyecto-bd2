/* ============================================================
   99. RESET DE DESARROLLO
   Elimina TODOS los objetos de dbo en PharmaInventory (FKs, tablas,
   vistas, procedimientos, funciones, tipos) para poder re-desplegar
   desde cero. Generico: no enumera nombres, recorre sys.* dinamicamente.

   Cada batch (separado por GO) se ejecuta como una sentencia INDEPENDIENTE
   -- asi es como lo corren sqlcmd, SSMS y la herramienta DbDeploy. Un
   "IF DB_ID(...) IS NULL RETURN" en un batch NO evita que el siguiente
   batch corra, por eso cada bloque abajo trae su propio guard.

   DROP VIEW/PROCEDURE/FUNCTION/TABLE/TYPE NO aceptan nombre de 3 partes
   (a diferencia de ALTER TABLE, que si lo acepta -- por eso el bloque de
   FKs usa PharmaInventory.dbo.X directo). Para esos, el SQL dinamico arranca
   con "USE PharmaInventory;" y usa nombres de 2 partes (schema.objeto);
   USE cambia el contexto de la sesion y persiste tras el EXEC.

   NO borra la base de datos en si, solo su contenido.
   ============================================================ */

-- 1) Foreign keys (deben irse antes que las tablas, sin importar el orden).
-- ALTER TABLE si acepta nombre de 3 partes, no necesita USE.
IF DB_ID(N'PharmaInventory') IS NOT NULL
BEGIN
    DECLARE @sql_fk NVARCHAR(MAX) = N'';
    SELECT @sql_fk += N'ALTER TABLE PharmaInventory.' + QUOTENAME(OBJECT_SCHEMA_NAME(parent_object_id, DB_ID(N'PharmaInventory'))) +
                      N'.' + QUOTENAME(OBJECT_NAME(parent_object_id, DB_ID(N'PharmaInventory'))) +
                      N' DROP CONSTRAINT ' + QUOTENAME(name) + N';' + CHAR(10)
    FROM PharmaInventory.sys.foreign_keys;

    IF LEN(@sql_fk) > 0 EXEC sp_executesql @sql_fk;
END
GO

-- 2) Vistas
IF DB_ID(N'PharmaInventory') IS NOT NULL
BEGIN
    DECLARE @sql_v NVARCHAR(MAX) = N'USE PharmaInventory; ';
    SELECT @sql_v += N'DROP VIEW ' + QUOTENAME(s.name) + N'.' + QUOTENAME(v.name) + N';' + CHAR(10)
    FROM PharmaInventory.sys.views v
    INNER JOIN PharmaInventory.sys.schemas s ON s.schema_id = v.schema_id;

    EXEC sp_executesql @sql_v;
END
GO

-- 3) Procedimientos
IF DB_ID(N'PharmaInventory') IS NOT NULL
BEGIN
    DECLARE @sql_p NVARCHAR(MAX) = N'USE PharmaInventory; ';
    SELECT @sql_p += N'DROP PROCEDURE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(p.name) + N';' + CHAR(10)
    FROM PharmaInventory.sys.procedures p
    INNER JOIN PharmaInventory.sys.schemas s ON s.schema_id = p.schema_id;

    EXEC sp_executesql @sql_p;
END
GO

-- 4) Funciones (escalares, inline TVF, multi-statement TVF)
IF DB_ID(N'PharmaInventory') IS NOT NULL
BEGIN
    DECLARE @sql_f NVARCHAR(MAX) = N'USE PharmaInventory; ';
    SELECT @sql_f += N'DROP FUNCTION ' + QUOTENAME(s.name) + N'.' + QUOTENAME(o.name) + N';' + CHAR(10)
    FROM PharmaInventory.sys.objects o
    INNER JOIN PharmaInventory.sys.schemas s ON s.schema_id = o.schema_id
    WHERE o.type IN ('FN','IF','TF');

    EXEC sp_executesql @sql_f;
END
GO

-- 5) Tablas
IF DB_ID(N'PharmaInventory') IS NOT NULL
BEGIN
    DECLARE @sql_t NVARCHAR(MAX) = N'USE PharmaInventory; ';
    SELECT @sql_t += N'DROP TABLE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(t.name) + N';' + CHAR(10)
    FROM PharmaInventory.sys.tables t
    INNER JOIN PharmaInventory.sys.schemas s ON s.schema_id = t.schema_id;

    EXEC sp_executesql @sql_t;
END
GO

-- 6) Tipos de tabla (TVP)
IF DB_ID(N'PharmaInventory') IS NOT NULL
BEGIN
    DECLARE @sql_tt NVARCHAR(MAX) = N'USE PharmaInventory; ';
    SELECT @sql_tt += N'DROP TYPE ' + QUOTENAME(s.name) + N'.' + QUOTENAME(tt.name) + N';' + CHAR(10)
    FROM PharmaInventory.sys.table_types tt
    INNER JOIN PharmaInventory.sys.schemas s ON s.schema_id = tt.schema_id;

    EXEC sp_executesql @sql_tt;
END
GO

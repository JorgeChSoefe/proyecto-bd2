using System.Text.RegularExpressions;
using Microsoft.Data.SqlClient;

namespace PharmaInventory.DbDeploy;

/// <summary>
/// Despliega el esquema de PharmaInventory contra un SQL Server real leyendo
/// los .sql de scrips_bd/ en orden y ejecutandolos separados por GO.
/// Existe porque el host de desarrollo no tiene sqlcmd instalado.
///
/// Uso:
///   dotnet run --project tools/DbDeploy -- --conn "Server=host,1433;User Id=sa;Password=***;TrustServerCertificate=True" [--scripts scrips_bd] [--reset]
/// </summary>
internal static class Program
{
    // Orden de despliegue. 00_Script_Completo_Inventario.sql es una
    // concatenacion generada de 01-08 (fuente de verdad); no se ejecuta
    // aparte porque duplicaria todo. Proyecto BD 2.sql es el export
    // original de dbdiagram (no es T-SQL valido) y nunca se ejecuta.
    private static readonly string[] DeployOrder =
    [
        "10_Schema_Tablas.sql",
        "01_Tipos_Tabla_TVP.sql",
        "02_Seguridad_Accesos.sql",
        "03_Catalogos.sql",
        "04_Productos_Medicamentos.sql",
        "05_Inventario_Kardex.sql",
        "06_Clientes_Recetas.sql",
        "07_Ventas.sql",
        "08_Compras.sql",
        "11_Seed_Datos.sql",
    ];

    private const string ResetFile = "99_Reset.sql";

    // Separa por lineas que son SOLO "GO" (con espacio opcional), como hace sqlcmd/SSMS.
    private static readonly Regex GoSeparator = new(@"^\s*GO\s*$", RegexOptions.Multiline | RegexOptions.IgnoreCase | RegexOptions.Compiled);

    private static int Main(string[] args)
    {
        string? connectionString = null;
        string scriptsDir = Path.Combine(Directory.GetCurrentDirectory(), "scrips_bd");
        bool reset = false;
        bool verify = false;
        bool smoke = false;

        for (var i = 0; i < args.Length; i++)
        {
            switch (args[i])
            {
                case "--conn":
                    connectionString = args[++i];
                    break;
                case "--scripts":
                    scriptsDir = Path.GetFullPath(args[++i]);
                    break;
                case "--reset":
                    reset = true;
                    break;
                case "--verify":
                    verify = true;
                    break;
                case "--smoke":
                    smoke = true;
                    break;
                case "-h":
                case "--help":
                    PrintUsage();
                    return 0;
                default:
                    Console.Error.WriteLine($"Argumento desconocido: {args[i]}");
                    PrintUsage();
                    return 1;
            }
        }

        if (string.IsNullOrWhiteSpace(connectionString))
        {
            Console.Error.WriteLine("Falta --conn.");
            PrintUsage();
            return 1;
        }

        if (!Directory.Exists(scriptsDir))
        {
            Console.Error.WriteLine($"No existe el directorio de scripts: {scriptsDir}");
            return 1;
        }

        // La conexion persistente se abre contra 'master': el propio
        // 10_Schema_Tablas.sql crea PharmaInventory si no existe y luego hace
        // "USE PharmaInventory", lo que cambia el contexto de BD de esta
        // misma conexion para todos los batches subsiguientes (de cualquier
        // archivo). Por eso todo corre en una sola conexion.
        var builder = new SqlConnectionStringBuilder(connectionString)
        {
            InitialCatalog = "master",
        };
        if (!connectionString.Contains("Encrypt", StringComparison.OrdinalIgnoreCase))
            builder.Encrypt = true;
        if (!connectionString.Contains("TrustServerCertificate", StringComparison.OrdinalIgnoreCase))
            builder.TrustServerCertificate = true;

        using var connection = new SqlConnection(builder.ConnectionString);

        try
        {
            connection.Open();
        }
        catch (Exception ex)
        {
            Console.Error.WriteLine($"No se pudo conectar a {builder.DataSource}: {ex.Message}");
            return 1;
        }

        Console.WriteLine($"Conectado a {builder.DataSource} como {builder.UserID}.");

        try
        {
            if (reset)
            {
                RunFile(connection, Path.Combine(scriptsDir, ResetFile));
            }

            foreach (var fileName in DeployOrder)
            {
                RunFile(connection, Path.Combine(scriptsDir, fileName));
            }
        }
        catch (DeployException ex)
        {
            Console.Error.WriteLine();
            Console.Error.WriteLine($"FALLO en {ex.FileName}, batch #{ex.BatchNumber}:");
            Console.Error.WriteLine(ex.InnerException?.Message ?? ex.Message);
            Console.Error.WriteLine();
            Console.Error.WriteLine("---- SQL del batch que fallo ----");
            Console.Error.WriteLine(ex.BatchSql);
            return 1;
        }

        Console.WriteLine();
        Console.WriteLine(reset
            ? "Reset + despliegue completo: PharmaInventory quedo lista desde cero."
            : "Despliegue completo (re-ejecutable: los objetos ya existentes se re-crearon con CREATE OR ALTER).");

        if (verify)
        {
            RunVerify(builder.ConnectionString);
        }

        if (smoke)
        {
            RunSmoke(builder.ConnectionString);
        }

        return 0;
    }

    /// <summary>
    /// Sanity check post-deploy: confirma que el seed cargo, que el stock/PPP
    /// quedaron coherentes tras el flujo compra->recibir, y que
    /// vw_ProductosPorVencer ve el lote de vencimiento corto del seed.
    /// </summary>
    private static void RunVerify(string masterConnectionString)
    {
        Console.WriteLine();
        Console.WriteLine("==== VERIFICACION ====");

        using var conn = new SqlConnection(masterConnectionString);
        conn.Open();
        using (var useCmd = conn.CreateCommand())
        {
            useCmd.CommandText = "USE PharmaInventory;";
            useCmd.ExecuteNonQuery();
        }

        PrintQuery(conn, "Conteo de filas por tabla clave", """
            SELECT 'roles' t, COUNT(*) filas FROM roles
            UNION ALL SELECT 'permisos', COUNT(*) FROM permisos
            UNION ALL SELECT 'usuarios', COUNT(*) FROM usuarios
            UNION ALL SELECT 'productos', COUNT(*) FROM productos
            UNION ALL SELECT 'medicamentos', COUNT(*) FROM medicamentos
            UNION ALL SELECT 'lotes', COUNT(*) FROM lotes
            UNION ALL SELECT 'kardex', COUNT(*) FROM kardex
            UNION ALL SELECT 'clientes', COUNT(*) FROM clientes
            UNION ALL SELECT 'recetas', COUNT(*) FROM recetas
            UNION ALL SELECT 'compras', COUNT(*) FROM compras
            """);

        PrintQuery(conn, "Stock y costo promedio ponderado por producto", """
            SELECT codigo_sku, nombre, stock_actual, precio_promedio_pond, bajo_stock_minimo
            FROM vw_StockActual
            ORDER BY codigo_sku
            """);

        PrintQuery(conn, "Lotes (crudo)", """
            SELECT id_lote, numero_lote, id_producto, cantidad_inicial, cantidad_actual, fecha_vencimiento, activo
            FROM lotes ORDER BY id_lote
            """);

        PrintQuery(conn, "Detalle de compras (crudo)", """
            SELECT id_detalle, id_compra, id_producto, cantidad, precio_unitario, id_lote
            FROM detalle_compras ORDER BY id_compra, id_detalle
            """);

        PrintQuery(conn, "Kardex (crudo)", """
            SELECT id_movimiento, tipo_movimiento, referencia_doc, id_referencia_doc,
                   id_producto, id_lote, cantidad_entrada, cantidad_salida, saldo_stock
            FROM kardex ORDER BY id_movimiento
            """);

        PrintQuery(conn, "Kardex del Paracetamol (debe mostrar 2 entradas)", """
            DECLARE @idp INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'PARA500');
            EXEC sp_Kardex_ListarPorProducto @id_producto = @idp;
            """);

        PrintQuery(conn, "Productos por vencer en 30 dias (debe listar LOTE-VENCE-PRONTO)", """
            EXEC sp_Inventario_ProductosPorVencer @dias = 30
            """);

        PrintQuery(conn, "Recetas pendientes", "EXEC sp_Receta_ListarPendientes");
    }

    /// <summary>
    /// Smoke test transaccional contra el seed: venta multi-producto (prueba
    /// el fix de @lotes_fefo en sp_Venta_Registrar), venta de controlado sin
    /// receta (debe rechazarse), venta con receta + anulacion (prueba que
    /// sp_Venta_Anular ya no corrompe precio_promedio_pond - bug B3), y un
    /// ajuste manual positivo (prueba que sube el stock - bug B1). Corre como
    /// un solo script y vuelca un log a una tabla, para no abortar en la
    /// primera falla esperada (los BEGIN TRY/CATCH internos capturan cada paso).
    /// </summary>
    private static void RunSmoke(string masterConnectionString)
    {
        Console.WriteLine();
        Console.WriteLine("==== SMOKE TEST ====");

        using var conn = new SqlConnection(masterConnectionString);
        conn.Open();
        using (var useCmd = conn.CreateCommand())
        {
            useCmd.CommandText = "USE PharmaInventory;";
            useCmd.ExecuteNonQuery();
        }

        PrintQuery(conn, "Flujo transaccional (venta multi-producto, receta, anulacion, ajuste)", """
            DECLARE @log TABLE (paso NVARCHAR(200), resultado NVARCHAR(MAX));

            DECLARE @id_ibu INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'IBU400');
            DECLARE @id_diaz INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'DIAZ5');
            DECLARE @id_amox INT = (SELECT id_producto FROM productos WHERE codigo_sku = 'AMOX500');
            DECLARE @id_empleado INT = (SELECT id_empleado FROM empleados WHERE email = 'admin@farmacia.cr');
            DECLARE @id_usuario INT = (SELECT id_usuario FROM usuarios WHERE nombre_usuario = 'admin');
            DECLARE @id_cliente INT = (SELECT id_cliente FROM clientes WHERE identificacion = '1-1111-1111');
            DECLARE @id_receta INT = (SELECT id_receta FROM recetas WHERE numero_receta = 'RX-0001');

            -- Paso 1: venta multi-producto sin receta (Ibuprofeno + Loratadina)
            DECLARE @detalle1 dbo.TipoDetalleVenta;
            INSERT INTO @detalle1 (id_producto, cantidad, precio_unitario)
            SELECT id_producto, 5, precio_venta FROM productos WHERE codigo_sku IN ('IBU400','LORA10');

            DECLARE @id_venta1 INT;
            BEGIN TRY
                EXEC sp_Venta_Registrar @id_empleado=@id_empleado, @id_cliente=NULL, @id_usuario=@id_usuario,
                    @id_receta=NULL, @detalle=@detalle1, @id_venta_creada=@id_venta1 OUTPUT;
                INSERT INTO @log VALUES ('1. Venta multi-producto (IBU400+LORA10) sin receta', CONCAT('OK, id_venta=', @id_venta1));
            END TRY
            BEGIN CATCH
                INSERT INTO @log VALUES ('1. Venta multi-producto sin receta', CONCAT('ERROR: ', ERROR_MESSAGE()));
            END CATCH

            -- Prueba directa del fix de @lotes_fefo: cada linea debe apuntar al LOTE de SU PROPIO producto
            INSERT INTO @log
            SELECT '   verificacion lote<->producto (fix @lotes_fefo)',
                   CONCAT('detalle_id=', dv.id_detalle, ' producto_venta=', dv.id_producto, ' producto_lote=', l.id_producto,
                          CASE WHEN dv.id_producto = l.id_producto THEN ' OK' ELSE ' *** MISMATCH ***' END)
            FROM detalle_ventas dv
            INNER JOIN lotes l ON l.id_lote = dv.id_lote
            WHERE dv.id_venta = @id_venta1;

            -- Paso 2: venta de controlado (Diazepam) sin receta -> debe rechazarse (50051)
            DECLARE @detalle2 dbo.TipoDetalleVenta;
            INSERT INTO @detalle2 (id_producto, cantidad, precio_unitario)
            SELECT @id_diaz, 2, precio_venta FROM productos WHERE id_producto = @id_diaz;

            DECLARE @id_venta2 INT;
            BEGIN TRY
                EXEC sp_Venta_Registrar @id_empleado=@id_empleado, @id_cliente=NULL, @id_usuario=@id_usuario,
                    @id_receta=NULL, @detalle=@detalle2, @id_venta_creada=@id_venta2 OUTPUT;
                INSERT INTO @log VALUES ('2. Venta de Diazepam sin receta', CONCAT('*** NO debio pasar *** id_venta=', @id_venta2));
            END TRY
            BEGIN CATCH
                INSERT INTO @log VALUES ('2. Venta de Diazepam sin receta', CONCAT('OK (rechazada): ', ERROR_MESSAGE()));
            END CATCH

            -- Paso 3: venta de Amoxicilina cubriendo la receta RX-0001 (prescrita 21) -> debe pasar y dispensarla
            DECLARE @detalle3 dbo.TipoDetalleVenta;
            INSERT INTO @detalle3 (id_producto, cantidad, precio_unitario)
            SELECT @id_amox, 21, precio_venta FROM productos WHERE id_producto = @id_amox;

            DECLARE @id_venta3 INT;
            DECLARE @ppp_amox_antes DECIMAL(18,4) = (SELECT precio_promedio_pond FROM productos WHERE id_producto = @id_amox);
            BEGIN TRY
                EXEC sp_Venta_Registrar @id_empleado=@id_empleado, @id_cliente=@id_cliente, @id_usuario=@id_usuario,
                    @id_receta=@id_receta, @detalle=@detalle3, @id_venta_creada=@id_venta3 OUTPUT;
                INSERT INTO @log VALUES ('3. Venta Amoxicilina con receta RX-0001', CONCAT('OK, id_venta=', @id_venta3));
            END TRY
            BEGIN CATCH
                INSERT INTO @log VALUES ('3. Venta Amoxicilina con receta RX-0001', CONCAT('ERROR: ', ERROR_MESSAGE()));
            END CATCH

            INSERT INTO @log
            SELECT '   receta RX-0001 dispensada tras la venta?', CAST(dispensada AS NVARCHAR(10)) FROM recetas WHERE id_receta = @id_receta;

            -- Paso 4: anular la venta 3 y verificar que precio_promedio_pond NO cambio (regresion B3)
            BEGIN TRY
                EXEC sp_Venta_Anular @id_venta=@id_venta3, @id_usuario=@id_usuario;
                INSERT INTO @log VALUES ('4. Anular venta 3 (Amoxicilina)', 'OK');
            END TRY
            BEGIN CATCH
                INSERT INTO @log VALUES ('4. Anular venta 3', CONCAT('ERROR: ', ERROR_MESSAGE()));
            END CATCH

            DECLARE @ppp_amox_despues DECIMAL(18,4) = (SELECT precio_promedio_pond FROM productos WHERE id_producto = @id_amox);
            INSERT INTO @log VALUES ('   PPP Amoxicilina antes/despues de anular (regresion B3)',
                CONCAT('antes=', @ppp_amox_antes, ' despues=', @ppp_amox_despues,
                       CASE WHEN @ppp_amox_antes = @ppp_amox_despues THEN ' OK (sin corrupcion)' ELSE ' *** CORRUPTO ***' END));

            INSERT INTO @log
            SELECT '   receta RX-0001 dispensada tras anular (debe revertir)?', CAST(dispensada AS NVARCHAR(10)) FROM recetas WHERE id_receta = @id_receta;

            -- Paso 5: ajuste manual positivo debe SUBIR el stock (regresion B1)
            DECLARE @stock_antes INT = (SELECT stock_actual FROM productos WHERE id_producto = @id_ibu);
            DECLARE @id_mov_ajuste INT;
            EXEC sp_Inventario_AjusteManual @id_producto=@id_ibu, @id_lote=NULL, @cantidad=15,
                @motivo='Conteo fisico - smoke test', @id_usuario=@id_usuario, @id_movimiento_creado=@id_mov_ajuste OUTPUT;
            DECLARE @stock_despues INT = (SELECT stock_actual FROM productos WHERE id_producto = @id_ibu);
            INSERT INTO @log VALUES ('5. Ajuste manual +15 Ibuprofeno (regresion B1)',
                CONCAT('antes=', @stock_antes, ' despues=', @stock_despues,
                       CASE WHEN @stock_despues = @stock_antes + 15 THEN ' OK' ELSE ' *** FALLO ***' END));

            INSERT INTO @log
            SELECT '   observaciones del ajuste (motivo persistido en kardex)?', observaciones FROM kardex WHERE id_movimiento = @id_mov_ajuste;

            SELECT * FROM @log;
            """);
    }

    private static void PrintQuery(SqlConnection conn, string title, string sql)
    {
        Console.WriteLine();
        Console.WriteLine($"-- {title}");
        using var cmd = conn.CreateCommand();
        cmd.CommandText = sql;
        using var reader = cmd.ExecuteReader();

        var resultSet = 0;
        do
        {
            resultSet++;
            if (reader.FieldCount == 0) continue;

            if (resultSet > 1) Console.WriteLine($"  [resultset #{resultSet}]");
            var columns = Enumerable.Range(0, reader.FieldCount).Select(reader.GetName).ToArray();
            Console.WriteLine(string.Join(" | ", columns));

            var rows = 0;
            while (reader.Read())
            {
                var values = Enumerable.Range(0, reader.FieldCount).Select(i => reader.IsDBNull(i) ? "NULL" : reader.GetValue(i)?.ToString());
                Console.WriteLine(string.Join(" | ", values));
                rows++;
            }

            if (rows == 0) Console.WriteLine("(sin filas)");
        } while (reader.NextResult());
    }

    private static void RunFile(SqlConnection connection, string path)
    {
        if (!File.Exists(path))
            throw new DeployException(Path.GetFileName(path), 0, "(archivo no encontrado)", new FileNotFoundException(path));

        var fileName = Path.GetFileName(path);
        var script = File.ReadAllText(path);
        var batches = GoSeparator.Split(script)
            .Select(b => b.Trim())
            .Where(b => b.Length > 0)
            .ToList();

        Console.WriteLine($"-> {fileName} ({batches.Count} batches)");

        for (var i = 0; i < batches.Count; i++)
        {
            var batch = batches[i];
            using var cmd = connection.CreateCommand();
            cmd.CommandText = batch;
            cmd.CommandTimeout = 120;
            try
            {
                cmd.ExecuteNonQuery();
            }
            catch (Exception ex)
            {
                throw new DeployException(fileName, i + 1, batch, ex);
            }
        }
    }

    private static void PrintUsage()
    {
        Console.WriteLine("""
            Uso:
              dotnet run --project tools/DbDeploy -- --conn "<connection string>" [--scripts <dir>] [--reset]

            Opciones:
              --conn <connstring>   Cadena de conexion a SQL Server (obligatorio). El Initial Catalog
                                    se ignora: la primera conexion siempre abre contra 'master',
                                    porque el propio script crea/usa PharmaInventory.
              --scripts <dir>       Carpeta con los .sql (default: ./scrips_bd relativo al cwd).
              --reset               Corre 99_Reset.sql antes de desplegar (borra todos los objetos
                                    de dbo en PharmaInventory; no borra la base en si).
              --verify              Corre consultas de verificacion post-deploy (conteos, stock,
                                    kardex, productos por vencer, recetas pendientes).
              --smoke               Corre un flujo transaccional real (venta multi-producto,
                                    receta, anulacion, ajuste manual) para probar las regresiones
                                    B1/B3/B5. Escribe datos de prueba en la base.
            """);
    }
}

internal sealed class DeployException(string fileName, int batchNumber, string batchSql, Exception inner)
    : Exception($"{fileName} batch #{batchNumber} failed", inner)
{
    public string FileName { get; } = fileName;
    public int BatchNumber { get; } = batchNumber;
    public string BatchSql { get; } = batchSql;
}

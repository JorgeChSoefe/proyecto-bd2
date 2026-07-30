using System.Data;
using Dapper;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Infrastructure.Persistence;

namespace PharmaInventory.Infrastructure.Repositories;

public sealed class ProductoRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IProductoRepository
{
    public Task<int> InsertarAsync(ProductoRequest request, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var p = new DynamicParameters();
        p.Add("@nombre", request.Nombre);
        p.Add("@nombre_generico", request.NombreGenerico);
        p.Add("@codigo_sku", request.CodigoSku);
        p.Add("@codigo_barras", request.CodigoBarras);
        p.Add("@precio_costo", request.PrecioCosto);
        p.Add("@precio_venta", request.PrecioVenta);
        p.Add("@stock_minimo", request.StockMinimo);
        p.Add("@requiere_receta", request.RequiereReceta);
        p.Add("@id_categoria", request.IdCategoria);
        p.Add("@id_proveedor", request.IdProveedor);
        p.Add("@id_laboratorio", request.IdLaboratorio);
        p.Add("@id_presentacion", request.IdPresentacion);
        p.Add("@id_producto_creado", dbType: DbType.Int32, direction: ParameterDirection.Output);
        await conn.ExecuteAsync(new CommandDefinition("sp_Producto_Insertar", p, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return p.Get<int>("@id_producto_creado");
    });

    public Task ActualizarAsync(int id, ProductoUpdateRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Producto_Actualizar",
            new
            {
                id_producto = id, nombre = request.Nombre, nombre_generico = request.NombreGenerico,
                codigo_sku = request.CodigoSku, codigo_barras = request.CodigoBarras,
                precio_costo = request.PrecioCosto, precio_venta = request.PrecioVenta,
                stock_minimo = request.StockMinimo, requiere_receta = request.RequiereReceta,
                id_categoria = request.IdCategoria, id_proveedor = request.IdProveedor,
                id_laboratorio = request.IdLaboratorio, id_presentacion = request.IdPresentacion,
            },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task EliminarAsync(int id, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Producto_Eliminar", new { id_producto = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<ProductoDetalleDto?> ObtenerPorIdAsync(int id, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Producto_ObtenerPorId",
            new { id_producto = id }, commandType: CommandType.StoredProcedure, cancellationToken: ct));

        var producto = await multi.ReadSingleOrDefaultAsync<Producto>();
        if (producto is null) return null;

        var medicamento = await multi.ReadSingleOrDefaultAsync<Medicamento>();
        var principios = (await multi.ReadAsync<MedicamentoPrincipio>()).ToList();
        return new ProductoDetalleDto(producto, medicamento, principios);
    });

    public Task<PagedResult<Producto>> ListarAsync(PaginacionQuery query, int? idCategoria = null, CancellationToken ct = default) => RunAsync(async conn =>
    {
        using var multi = await conn.QueryMultipleAsync(new CommandDefinition("sp_Producto_Listar",
            new { pagina = query.Pagina, tamano = query.Tamano, busqueda = query.Busqueda, id_categoria = idCategoria },
            commandType: CommandType.StoredProcedure, cancellationToken: ct));
        var items = (await multi.ReadAsync<Producto>()).ToList();
        var total = await multi.ReadSingleAsync<int>();
        return new PagedResult<Producto> { Items = items, Total = total, Pagina = query.Pagina, Tamano = query.Tamano };
    });
}

public sealed class MedicamentoRepository(IDbConnectionFactory factory) : RepositoryBase(factory), IMedicamentoRepository
{
    public Task InsertarAsync(MedicamentoRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Medicamento_Insertar",
            new
            {
                id_producto = request.IdProducto, concentracion = request.Concentracion,
                via_administracion = EnumSnakeCase.ToSnake(request.ViaAdministracion), condiciones_almacenamiento = request.CondicionesAlmacenamiento,
                controlado = request.Controlado, numero_registro_sanitario = request.NumeroRegistroSanitario,
                indicaciones = request.Indicaciones, contraindicaciones = request.Contraindicaciones,
                efectos_secundarios = request.EfectosSecundarios, interacciones = request.Interacciones,
            },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task ActualizarAsync(int idMedicamento, MedicamentoUpdateRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_Medicamento_Actualizar",
            new
            {
                id_medicamento = idMedicamento, concentracion = request.Concentracion,
                via_administracion = EnumSnakeCase.ToSnake(request.ViaAdministracion), condiciones_almacenamiento = request.CondicionesAlmacenamiento,
                controlado = request.Controlado, numero_registro_sanitario = request.NumeroRegistroSanitario,
                indicaciones = request.Indicaciones, contraindicaciones = request.Contraindicaciones,
                efectos_secundarios = request.EfectosSecundarios, interacciones = request.Interacciones,
            },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task AsignarPrincipioAsync(MedicamentoPrincipioRequest request, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_MedicamentoPrincipio_Asignar",
            new
            {
                id_medicamento = request.IdMedicamento, id_principio = request.IdPrincipio,
                cantidad_por_dosis = request.CantidadPorDosis, unidad = request.Unidad,
            },
            commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task QuitarPrincipioAsync(int idMedicamento, int idPrincipio, CancellationToken ct = default) => RunAsync(conn =>
        conn.ExecuteAsync(new CommandDefinition("sp_MedicamentoPrincipio_Quitar",
            new { id_medicamento = idMedicamento, id_principio = idPrincipio }, commandType: CommandType.StoredProcedure, cancellationToken: ct)));

    public Task<IReadOnlyList<FichaMedicamentoDto>> ObtenerFichaPorProductoAsync(int idProducto, CancellationToken ct = default) => RunAsync(async conn =>
    {
        var rows = await conn.QueryAsync<FichaMedicamentoDto>(new CommandDefinition("sp_Producto_ObtenerFichaMedicamento",
            new { id_producto = idProducto }, commandType: CommandType.StoredProcedure, cancellationToken: ct));
        return (IReadOnlyList<FichaMedicamentoDto>)rows.ToList();
    });
}

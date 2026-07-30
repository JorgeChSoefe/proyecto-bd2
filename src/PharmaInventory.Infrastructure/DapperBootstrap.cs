using Dapper;
using PharmaInventory.Domain.Enums;
using PharmaInventory.Infrastructure.Persistence;

namespace PharmaInventory.Infrastructure;

/// <summary>
/// Configuracion global de Dapper -- se llama una sola vez al arrancar la Api
/// (ver DependencyInjection.AddInfrastructure). MatchNamesWithUnderscores
/// permite que columnas snake_case (id_producto) mapeen a propiedades
/// PascalCase (IdProducto) sin tener que escribir POCOs feos ni alias en
/// cada SP/vista.
/// </summary>
public static class DapperBootstrap
{
    private static bool _configured;

    public static void Configure()
    {
        if (_configured) return;
        _configured = true;

        SqlMapper.Settings.CommandTimeout = 30;
        DefaultTypeMap.MatchNamesWithUnderscores = true;

        SqlMapper.AddTypeHandler(new StringEnumTypeHandler<EstadoVenta>());
        SqlMapper.AddTypeHandler(new StringEnumTypeHandler<EstadoCompra>());
        SqlMapper.AddTypeHandler(new StringEnumTypeHandler<TipoMovimientoKardex>());
        SqlMapper.AddTypeHandler(new StringEnumTypeHandler<ViaAdministracion>());
        SqlMapper.AddTypeHandler(new StringEnumTypeHandler<TipoAlerta>());
    }
}

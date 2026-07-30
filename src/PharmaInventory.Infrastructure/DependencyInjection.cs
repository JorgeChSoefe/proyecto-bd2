using Microsoft.Extensions.DependencyInjection;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Infrastructure.Persistence;
using PharmaInventory.Infrastructure.Repositories;
using PharmaInventory.Infrastructure.Security;

namespace PharmaInventory.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services)
    {
        DapperBootstrap.Configure();

        services.AddSingleton<IDbConnectionFactory, SqlConnectionFactory>();
        services.AddSingleton<IPasswordHasher, BCryptPasswordHasher>();

        // Seguridad
        services.AddScoped<IRolRepository, RolRepository>();
        services.AddScoped<IPermisoRepository, PermisoRepository>();
        services.AddScoped<IEmpleadoRepository, EmpleadoRepository>();
        services.AddScoped<IUsuarioRepository, UsuarioRepository>();

        // Catalogos
        services.AddScoped<ICategoriaRepository, CategoriaRepository>();
        services.AddScoped<IProveedorRepository, ProveedorRepository>();
        services.AddScoped<ILaboratorioRepository, LaboratorioRepository>();
        services.AddScoped<IPrincipioActivoRepository, PrincipioActivoRepository>();
        services.AddScoped<IPresentacionRepository, PresentacionRepository>();

        // Productos y medicamentos
        services.AddScoped<IProductoRepository, ProductoRepository>();
        services.AddScoped<IMedicamentoRepository, MedicamentoRepository>();

        // Inventario
        services.AddScoped<IInventarioRepository, InventarioRepository>();
        services.AddScoped<IAlertaRepository, AlertaRepository>();

        // Clientes y recetas
        services.AddScoped<IClienteRepository, ClienteRepository>();
        services.AddScoped<IRecetaRepository, RecetaRepository>();

        // Ventas y compras
        services.AddScoped<IVentaRepository, VentaRepository>();
        services.AddScoped<ICompraRepository, CompraRepository>();

        return services;
    }
}

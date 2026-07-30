using System.Net;
using System.Net.Http.Json;
using Xunit;

namespace PharmaInventory.Tests.Integration;

/// <summary>
/// Prueba el flujo completo de autorizacion: [Authorize] + claims "perm" del
/// JWT + PermisoAuthorizationHandler, contra los permisos reales que
/// 11_Seed_Datos.sql asigna a Cajero (ventas/clientes/recetas/productos
/// limitados, SIN compras).
/// </summary>
[Collection("Integration")]
public class AuthorizationIntegrationTests(CustomWebApplicationFactory factory)
{
    [RequiresDatabaseFact]
    public async Task SinToken_Retorna401()
    {
        var client = factory.CreateClient();

        var response = await client.GetAsync("/api/ventas");

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [RequiresDatabaseFact]
    public async Task Cajero_SinPermisoDeCompras_Retorna403()
    {
        var client = await AuthHelper.AuthenticatedClientAsync(factory, "cajero1");

        var response = await client.GetAsync("/api/compras");

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [RequiresDatabaseFact]
    public async Task Cajero_ConPermisoDeVentas_Retorna200()
    {
        var client = await AuthHelper.AuthenticatedClientAsync(factory, "cajero1");

        var response = await client.GetAsync("/api/ventas");

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
    }

    [RequiresDatabaseFact]
    public async Task Cajero_SinPermisoDeAjustarInventario_Retorna403()
    {
        // "inventario:ajustar" es el permiso especial que CLAUDE.md 3.4 pide
        // reservar -- Cajero solo tiene "inventario:consultar" en el seed.
        var client = await AuthHelper.AuthenticatedClientAsync(factory, "cajero1");

        var response = await client.PostAsJsonAsync("/api/inventario/ajustes", new
        {
            idProducto = 1, idLote = (int?)null, cantidad = 1, motivo = "no deberia poder",
        });

        Assert.Equal(HttpStatusCode.Forbidden, response.StatusCode);
    }

    [RequiresDatabaseFact]
    public async Task Administrador_TieneAccesoATodosLosModulos()
    {
        var client = await AuthHelper.AuthenticatedClientAsync(factory, "admin");

        var respuestas = await Task.WhenAll(
            client.GetAsync("/api/compras"),
            client.GetAsync("/api/ventas"),
            client.GetAsync("/api/usuarios"),
            client.GetAsync("/api/inventario/stock"));

        Assert.All(respuestas, r => Assert.Equal(HttpStatusCode.OK, r.StatusCode));
    }
}

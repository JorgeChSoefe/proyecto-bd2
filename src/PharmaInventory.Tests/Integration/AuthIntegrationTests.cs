using System.Net;
using System.Net.Http.Json;
using PharmaInventory.Application.Dtos;
using Xunit;

namespace PharmaInventory.Tests.Integration;

[Collection("Integration")]
public class AuthIntegrationTests(CustomWebApplicationFactory factory)
{
    [RequiresDatabaseFact]
    public async Task Login_ConCredencialesValidas_RetornaTokenYPermisos()
    {
        var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/login", new LoginRequest("admin", AuthHelper.PasswordSeed));

        Assert.Equal(HttpStatusCode.OK, response.StatusCode);
        var body = await response.Content.ReadFromJsonAsync<LoginResponse>();
        Assert.NotNull(body);
        Assert.False(string.IsNullOrWhiteSpace(body!.Token));
        Assert.Equal("Administrador", body.NombreRol);

        // El token debe traer al menos un claim "perm" -- si vw_UsuarioPermisos
        // o sp_Usuario_ObtenerPermisos se rompen, el login "funciona" pero el
        // usuario queda sin poder hacer nada (ver PermisoAuthorizationHandler).
        var payload = DecodificarPayloadJwt(body.Token);
        Assert.Contains("\"perm\"", payload);
        Assert.Contains("productos:listar", payload);
    }

    [RequiresDatabaseFact]
    public async Task Login_ConPasswordIncorrecta_Retorna401()
    {
        var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/login", new LoginRequest("admin", "password-incorrecta"));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    [RequiresDatabaseFact]
    public async Task Login_ConUsuarioInexistente_Retorna401()
    {
        var client = factory.CreateClient();

        var response = await client.PostAsJsonAsync("/api/auth/login", new LoginRequest("usuario-que-no-existe", "cualquiera"));

        Assert.Equal(HttpStatusCode.Unauthorized, response.StatusCode);
    }

    private static string DecodificarPayloadJwt(string jwt)
    {
        var payloadBase64 = jwt.Split('.')[1];
        var padded = payloadBase64.PadRight(payloadBase64.Length + (4 - payloadBase64.Length % 4) % 4, '=')
            .Replace('-', '+').Replace('_', '/');
        return System.Text.Encoding.UTF8.GetString(Convert.FromBase64String(padded));
    }
}

using System.Net.Http.Json;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Tests.Integration;

internal static class AuthHelper
{
    /// <summary>Password de los 3 usuarios sembrados por 11_Seed_Datos.sql (admin/farmaceutico1/cajero1).</summary>
    public const string PasswordSeed = "Admin123!";

    public static async Task<string> LoginAsync(HttpClient client, string nombreUsuario, string password = PasswordSeed)
    {
        var response = await client.PostAsJsonAsync("/api/auth/login", new LoginRequest(nombreUsuario, password));
        response.EnsureSuccessStatusCode();
        var body = await response.Content.ReadFromJsonAsync<LoginResponse>();
        return body!.Token;
    }

    public static async Task<HttpClient> AuthenticatedClientAsync(CustomWebApplicationFactory factory, string nombreUsuario, string password = PasswordSeed)
    {
        var client = factory.CreateClient();
        var token = await LoginAsync(client, nombreUsuario, password);
        client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", token);
        return client;
    }
}

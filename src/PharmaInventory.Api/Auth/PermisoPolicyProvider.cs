using Microsoft.AspNetCore.Authorization;
using Microsoft.Extensions.Options;

namespace PharmaInventory.Api.Auth;

/// <summary>
/// Genera policies "perm:modulo:accion" al vuelo, sin tener que registrar
/// cada combinacion posible en Program.cs. Cualquier policy que no empiece
/// con el prefijo cae al provider por defecto (por si se agregan policies
/// normales mas adelante).
/// </summary>
public sealed class PermisoPolicyProvider : IAuthorizationPolicyProvider
{
    public const string Prefijo = "perm:";

    private readonly DefaultAuthorizationPolicyProvider _fallback;

    public PermisoPolicyProvider(IOptions<AuthorizationOptions> options)
    {
        _fallback = new DefaultAuthorizationPolicyProvider(options);
    }

    public Task<AuthorizationPolicy> GetDefaultPolicyAsync() => _fallback.GetDefaultPolicyAsync();

    public Task<AuthorizationPolicy?> GetFallbackPolicyAsync() => _fallback.GetFallbackPolicyAsync();

    public Task<AuthorizationPolicy?> GetPolicyAsync(string policyName)
    {
        if (!policyName.StartsWith(Prefijo, StringComparison.Ordinal))
            return _fallback.GetPolicyAsync(policyName);

        var partes = policyName[Prefijo.Length..].Split(':', 2);
        var policy = new AuthorizationPolicyBuilder()
            .RequireAuthenticatedUser()
            .AddRequirements(new PermisoRequirement(partes[0], partes[1]))
            .Build();

        return Task.FromResult<AuthorizationPolicy?>(policy);
    }
}

using Microsoft.AspNetCore.Authorization;

namespace PharmaInventory.Api.Auth;

public sealed class PermisoRequirement(string modulo, string accion) : IAuthorizationRequirement
{
    public string Modulo { get; } = modulo;
    public string Accion { get; } = accion;
}

public sealed class PermisoAuthorizationHandler : AuthorizationHandler<PermisoRequirement>
{
    protected override Task HandleRequirementAsync(AuthorizationHandlerContext context, PermisoRequirement requirement)
    {
        var valorEsperado = $"{requirement.Modulo}:{requirement.Accion}";
        if (context.User.HasClaim("perm", valorEsperado))
            context.Succeed(requirement);

        return Task.CompletedTask;
    }
}

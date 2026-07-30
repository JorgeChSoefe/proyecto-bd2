using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Api.Controllers;

public sealed record AsignarPermisoRequest(int IdPermiso);

[Route("api/permisos")]
public sealed class PermisosController(IPermisoRepository repo) : CatalogoControllerBase<Permiso, PermisoRequest>(repo, "permisos")
{
    [HttpGet("~/api/roles/{idRol:int}/permisos")]
    public async Task<ActionResult<IReadOnlyList<Permiso>>> ObtenerPermisosDeRol(int idRol, CancellationToken ct)
    {
        if (!TienePermiso("ver")) return Forbid();
        return Ok(await repo.ObtenerPermisosDeRolAsync(idRol, ct));
    }

    [HttpPost("~/api/roles/{idRol:int}/permisos")]
    public async Task<IActionResult> AsignarARol(int idRol, AsignarPermisoRequest request, CancellationToken ct)
    {
        if (!TienePermiso("editar")) return Forbid();
        await repo.AsignarARolAsync(idRol, request.IdPermiso, ct);
        return NoContent();
    }

    [HttpDelete("~/api/roles/{idRol:int}/permisos/{idPermiso:int}")]
    public async Task<IActionResult> RevocarDeRol(int idRol, int idPermiso, CancellationToken ct)
    {
        if (!TienePermiso("editar")) return Forbid();
        await repo.RevocarDeRolAsync(idRol, idPermiso, ct);
        return NoContent();
    }
}

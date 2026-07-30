using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;

namespace PharmaInventory.Api.Controllers;

/// <summary>
/// Los 8 catalogos simples (roles, permisos, empleados, categorias,
/// proveedores, laboratorios, principios_activos, presentaciones) son CRUD
/// identico: Insertar/Actualizar/Eliminar/ObtenerPorId/Listar contra su
/// propio SP (ver ICatalogoRepository). En vez de repetir el mismo
/// controller 8 veces, la forma vive aqui una sola vez; cada subclase solo
/// aporta el [Route] y el nombre de modulo para los permisos.
///
/// [RequierePermiso] no sirve aqui porque el modulo cambia por subclase y
/// los atributos son constantes de compilacion -- el chequeo se hace a mano
/// contra el claim "perm" (mismo criterio que PermisoAuthorizationHandler).
/// </summary>
[ApiController]
[Authorize]
public abstract class CatalogoControllerBase<TEntity, TRequest>(ICatalogoRepository<TEntity, TRequest> repo, string modulo) : ControllerBase
{
    /// <summary>Expuesto para que subclases con endpoints extra (ej. PermisosController) no necesiten inyectar el repo dos veces.</summary>
    protected ICatalogoRepository<TEntity, TRequest> Repo { get; } = repo;

    protected bool TienePermiso(string accion) => User.HasClaim("perm", $"{modulo}:{accion}");

    [HttpGet]
    public async Task<ActionResult<PagedResult<TEntity>>> Listar([FromQuery] PaginacionQuery query, CancellationToken ct)
    {
        if (!TienePermiso("listar")) return Forbid();
        return Ok(await Repo.ListarAsync(query, ct));
    }

    [HttpGet("{id:int}")]
    public async Task<ActionResult<TEntity>> ObtenerPorId(int id, CancellationToken ct)
    {
        if (!TienePermiso("ver")) return Forbid();
        var entidad = await Repo.ObtenerPorIdAsync(id, ct);
        return entidad is null ? NotFound() : Ok(entidad);
    }

    [HttpPost]
    public async Task<ActionResult<int>> Crear(TRequest request, CancellationToken ct)
    {
        if (!TienePermiso("crear")) return Forbid();
        var id = await Repo.InsertarAsync(request, ct);
        return CreatedAtAction(nameof(ObtenerPorId), new { id }, id);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Actualizar(int id, TRequest request, CancellationToken ct)
    {
        if (!TienePermiso("editar")) return Forbid();
        await Repo.ActualizarAsync(id, request, ct);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct)
    {
        if (!TienePermiso("eliminar")) return Forbid();
        await Repo.EliminarAsync(id, ct);
        return NoContent();
    }
}

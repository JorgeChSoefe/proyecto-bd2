using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Api.Auth;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/recetas")]
public sealed class RecetasController(IRecetaRepository repo) : ControllerBase
{
    [HttpPost]
    [RequierePermiso("recetas", "crear")]
    public async Task<ActionResult<int>> Registrar(RecetaRequest request, CancellationToken ct)
    {
        var id = await repo.RegistrarAsync(request, ct);
        return CreatedAtAction(nameof(ObtenerPorId), new { id }, id);
    }

    [HttpGet("{id:int}")]
    [RequierePermiso("recetas", "ver")]
    public async Task<ActionResult<RecetaDetalleDto>> ObtenerPorId(int id, CancellationToken ct)
    {
        var detalle = await repo.ObtenerPorIdAsync(id, ct);
        return detalle is null ? NotFound() : Ok(detalle);
    }

    [HttpGet("pendientes")]
    [RequierePermiso("recetas", "listar")]
    public async Task<ActionResult<PagedResult<Receta>>> ListarPendientes([FromQuery] PaginacionQuery query, [FromQuery] int? idCliente, CancellationToken ct) =>
        Ok(await repo.ListarPendientesAsync(query, idCliente, ct));
}

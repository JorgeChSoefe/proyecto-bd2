using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Api.Auth;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Domain.Enums;

namespace PharmaInventory.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/compras")]
public sealed class ComprasController(ICompraRepository compras) : ControllerBase
{
    private int UsuarioActualId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>sp_Compra_Registrar: deja la compra en 'pendiente', sin lotes ni kardex todavia.</summary>
    [HttpPost]
    [RequierePermiso("compras", "crear")]
    public async Task<ActionResult<int>> Registrar(CompraRequest request, CancellationToken ct)
    {
        var id = await compras.RegistrarAsync(request, UsuarioActualId, ct);
        return CreatedAtAction(nameof(ObtenerPorId), new { id }, id);
    }

    /// <summary>
    /// sp_Compra_Recibir: cada linea debe traer IdDetalle (obtenido de GET
    /// /api/compras/{id} tras registrar) para calzar 1:1 con la fila real de
    /// detalle_compras -- ver bug B4 en 08_Compras.sql.
    /// </summary>
    [HttpPatch("{id:int}/recibir")]
    [RequierePermiso("compras", "recibir")]
    public async Task<IActionResult> Recibir(int id, CompraRecibirRequest request, CancellationToken ct)
    {
        await compras.RecibirAsync(id, request, UsuarioActualId, ct);
        return NoContent();
    }

    [HttpPatch("{id:int}/anular")]
    [RequierePermiso("compras", "anular")]
    public async Task<IActionResult> Anular(int id, CancellationToken ct)
    {
        await compras.AnularAsync(id, ct);
        return NoContent();
    }

    [HttpGet("{id:int}")]
    [RequierePermiso("compras", "ver")]
    public async Task<ActionResult<CompraDetalleDto>> ObtenerPorId(int id, CancellationToken ct)
    {
        var detalle = await compras.ObtenerPorIdAsync(id, ct);
        return detalle is null ? NotFound() : Ok(detalle);
    }

    [HttpGet]
    [RequierePermiso("compras", "listar")]
    public async Task<ActionResult<PagedResult<Compra>>> Listar(
        [FromQuery] PaginacionQuery query, [FromQuery] EstadoCompra? estado,
        [FromQuery] DateOnly? fechaDesde, [FromQuery] DateOnly? fechaHasta, CancellationToken ct) =>
        Ok(await compras.ListarAsync(query, estado, fechaDesde, fechaHasta, ct));
}

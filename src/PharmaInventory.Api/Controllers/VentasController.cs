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
[Route("api/ventas")]
public sealed class VentasController(IVentaRepository ventas) : ControllerBase
{
    private int UsuarioActualId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    /// <summary>sp_Venta_Registrar: el mas critico del sistema (FEFO, validacion de receta, kardex por lote).</summary>
    [HttpPost]
    [RequierePermiso("ventas", "crear")]
    public async Task<ActionResult<int>> Registrar(VentaRequest request, CancellationToken ct)
    {
        var id = await ventas.RegistrarAsync(request, UsuarioActualId, ct);
        return CreatedAtAction(nameof(ObtenerPorId), new { id }, id);
    }

    [HttpGet("{id:int}")]
    [RequierePermiso("ventas", "ver")]
    public async Task<ActionResult<VentaDetalleDto>> ObtenerPorId(int id, CancellationToken ct)
    {
        var detalle = await ventas.ObtenerPorIdAsync(id, ct);
        return detalle is null ? NotFound() : Ok(detalle);
    }

    [HttpGet]
    [RequierePermiso("ventas", "listar")]
    public async Task<ActionResult<PagedResult<Venta>>> Listar(
        [FromQuery] PaginacionQuery query, [FromQuery] EstadoVenta? estado,
        [FromQuery] DateOnly? fechaDesde, [FromQuery] DateOnly? fechaHasta, CancellationToken ct) =>
        Ok(await ventas.ListarAsync(query, estado, fechaDesde, fechaHasta, ct));

    /// <summary>sp_Venta_Anular: reversa de stock por costo original (no precio de venta), ventana de dias, revierte receta.</summary>
    [HttpPatch("{id:int}/anular")]
    [RequierePermiso("ventas", "anular")]
    public async Task<IActionResult> Anular(int id, CancellationToken ct)
    {
        await ventas.AnularAsync(id, UsuarioActualId, ct);
        return NoContent();
    }
}

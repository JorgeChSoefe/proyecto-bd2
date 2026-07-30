using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Api.Auth;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using PharmaInventory.Domain.Enums;
using PharmaInventory.Infrastructure.Persistence;

namespace PharmaInventory.Api.Controllers;

[ApiController]
[Authorize]
[Route("api/inventario")]
public sealed class InventarioController(IInventarioRepository inventario, IAlertaRepository alertas) : ControllerBase
{
    private int UsuarioActualId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);

    [HttpGet("stock")]
    [RequierePermiso("inventario", "consultar")]
    public async Task<ActionResult<PagedResult<StockActualDto>>> Stock([FromQuery] PaginacionQuery query, [FromQuery] bool soloBajoMinimo, CancellationToken ct) =>
        Ok(await inventario.ListarStockAsync(query, soloBajoMinimo, ct));

    [HttpGet("por-vencer")]
    [RequierePermiso("inventario", "consultar")]
    public async Task<ActionResult<IReadOnlyList<ProductoPorVencerDto>>> PorVencer([FromQuery] int dias = 30, CancellationToken ct = default) =>
        Ok(await inventario.ListarPorVencerAsync(dias, ct));

    [HttpGet("kardex/{idProducto:int}")]
    [RequierePermiso("inventario", "consultar")]
    public async Task<ActionResult<PagedResult<MovimientoKardex>>> Kardex(int idProducto, [FromQuery] PaginacionQuery query, CancellationToken ct) =>
        Ok(await inventario.ListarKardexPorProductoAsync(idProducto, query, ct));

    /// <summary>Lotes activos con stock de un producto -- selector de lote del ajuste manual (evita inferirlo del kardex).</summary>
    [HttpGet("lotes")]
    [RequierePermiso("inventario", "consultar")]
    public async Task<ActionResult<IReadOnlyList<LoteDisponibleDto>>> Lotes([FromQuery] int idProducto, CancellationToken ct) =>
        Ok(await inventario.ListarLotesPorProductoAsync(idProducto, ct));

    /// <summary>Unico endpoint de escritura directa de stock -- permiso especial "inventario:ajustar" (CLAUDE.md 3.4).</summary>
    [HttpPost("ajustes")]
    [RequierePermiso("inventario", "ajustar")]
    public async Task<ActionResult<int>> AjusteManual(AjusteManualRequest request, CancellationToken ct)
    {
        var idMovimiento = await inventario.AjusteManualAsync(request, UsuarioActualId, ct);
        return Ok(new { idMovimiento });
    }

    /// <summary>
    /// `tipo` llega como snake_case (ej. "stock_minimo", igual que el resto del
    /// contrato) -- se parsea a mano porque el model binder de query-string de
    /// ASP.NET no usa el JsonStringEnumConverter (eso solo aplica al body),
    /// asi que un [FromQuery] TipoAlerta? directo exigiria PascalCase exacto.
    /// </summary>
    [HttpGet("alertas")]
    [RequierePermiso("inventario", "consultar")]
    public async Task<ActionResult<PagedResult<AlertaStock>>> Alertas([FromQuery] PaginacionQuery query, [FromQuery] string? tipo, CancellationToken ct) =>
        Ok(await alertas.ListarAsync(query, ParseTipoAlerta(tipo), ct));

    private static TipoAlerta? ParseTipoAlerta(string? tipo) =>
        string.IsNullOrEmpty(tipo) ? null : Enum.Parse<TipoAlerta>(EnumSnakeCase.ToPascal(tipo), ignoreCase: true);

    [HttpPatch("alertas/{id:int}/resolver")]
    [RequierePermiso("inventario", "resolver_alerta")]
    public async Task<IActionResult> ResolverAlerta(int id, CancellationToken ct)
    {
        await alertas.ResolverAsync(id, UsuarioActualId, ct);
        return NoContent();
    }
}

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
[Route("api/productos")]
public sealed class ProductosController(IProductoRepository productos, IMedicamentoRepository medicamentos) : ControllerBase
{
    [HttpGet]
    [RequierePermiso("productos", "listar")]
    public async Task<ActionResult<PagedResult<Producto>>> Listar([FromQuery] PaginacionQuery query, [FromQuery] int? idCategoria, CancellationToken ct) =>
        Ok(await productos.ListarAsync(query, idCategoria, ct));

    [HttpGet("{id:int}")]
    [RequierePermiso("productos", "ver")]
    public async Task<ActionResult<ProductoDetalleDto>> ObtenerPorId(int id, CancellationToken ct)
    {
        var detalle = await productos.ObtenerPorIdAsync(id, ct);
        return detalle is null ? NotFound() : Ok(detalle);
    }

    [HttpPost]
    [RequierePermiso("productos", "crear")]
    public async Task<ActionResult<int>> Crear(ProductoRequest request, CancellationToken ct)
    {
        var id = await productos.InsertarAsync(request, ct);
        return CreatedAtAction(nameof(ObtenerPorId), new { id }, id);
    }

    [HttpPut("{id:int}")]
    [RequierePermiso("productos", "editar")]
    public async Task<IActionResult> Actualizar(int id, ProductoUpdateRequest request, CancellationToken ct)
    {
        await productos.ActualizarAsync(id, request, ct);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [RequierePermiso("productos", "eliminar")]
    public async Task<IActionResult> Eliminar(int id, CancellationToken ct)
    {
        await productos.EliminarAsync(id, ct);
        return NoContent();
    }

    [HttpGet("{id:int}/medicamento")]
    [RequierePermiso("medicamentos", "ver")]
    public async Task<ActionResult<IReadOnlyList<FichaMedicamentoDto>>> ObtenerFichaMedicamento(int id, CancellationToken ct) =>
        Ok(await medicamentos.ObtenerFichaPorProductoAsync(id, ct));

    [HttpPost("{id:int}/medicamento")]
    [RequierePermiso("medicamentos", "crear")]
    public async Task<IActionResult> CrearFichaMedicamento(int id, MedicamentoUpdateRequest request, CancellationToken ct)
    {
        await medicamentos.InsertarAsync(new MedicamentoRequest(
            id, request.Concentracion, request.ViaAdministracion, request.CondicionesAlmacenamiento,
            request.Controlado, request.NumeroRegistroSanitario, request.Indicaciones,
            request.Contraindicaciones, request.EfectosSecundarios, request.Interacciones), ct);
        return CreatedAtAction(nameof(ObtenerFichaMedicamento), new { id }, null);
    }
}

[ApiController]
[Authorize]
[Route("api/medicamentos")]
public sealed class MedicamentosController(IMedicamentoRepository medicamentos) : ControllerBase
{
    [HttpPut("{idMedicamento:int}")]
    [RequierePermiso("medicamentos", "editar")]
    public async Task<IActionResult> Actualizar(int idMedicamento, MedicamentoUpdateRequest request, CancellationToken ct)
    {
        await medicamentos.ActualizarAsync(idMedicamento, request, ct);
        return NoContent();
    }

    [HttpPost("{idMedicamento:int}/principios")]
    [RequierePermiso("medicamentos", "editar")]
    public async Task<IActionResult> AsignarPrincipio(int idMedicamento, MedicamentoPrincipioAsignarRequest request, CancellationToken ct)
    {
        await medicamentos.AsignarPrincipioAsync(new MedicamentoPrincipioRequest(idMedicamento, request.IdPrincipio, request.CantidadPorDosis, request.Unidad), ct);
        return NoContent();
    }

    [HttpDelete("{idMedicamento:int}/principios/{idPrincipio:int}")]
    [RequierePermiso("medicamentos", "editar")]
    public async Task<IActionResult> QuitarPrincipio(int idMedicamento, int idPrincipio, CancellationToken ct)
    {
        await medicamentos.QuitarPrincipioAsync(idMedicamento, idPrincipio, ct);
        return NoContent();
    }
}

public sealed record MedicamentoPrincipioAsignarRequest(int IdPrincipio, decimal CantidadPorDosis, string Unidad);

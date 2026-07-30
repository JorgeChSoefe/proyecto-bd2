using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Api.Auth;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Api.Controllers;

/// <summary>Contrato de entrada por HTTP: el cliente manda password en claro, nunca un hash.</summary>
public sealed record CrearUsuarioRequest(string NombreUsuario, string? Email, string Password, int IdRol, int? IdEmpleado);

[ApiController]
[Route("api/usuarios")]
[Authorize]
public sealed class UsuariosController(IUsuarioRepository usuarios, IPasswordHasher passwordHasher) : ControllerBase
{
    [HttpGet]
    [RequierePermiso("usuarios", "listar")]
    public async Task<ActionResult<PagedResult<UsuarioResponse>>> Listar([FromQuery] PaginacionQuery query, CancellationToken ct)
    {
        var pagina = await usuarios.ListarAsync(query, ct);
        return Ok(new PagedResult<UsuarioResponse>
        {
            Items = pagina.Items.Select(UsuarioResponse.De).ToList(), Total = pagina.Total, Pagina = pagina.Pagina, Tamano = pagina.Tamano,
        });
    }

    [HttpGet("{id:int}")]
    [RequierePermiso("usuarios", "ver")]
    public async Task<ActionResult<UsuarioResponse>> ObtenerPorId(int id, CancellationToken ct)
    {
        var usuario = await usuarios.ObtenerPorIdAsync(id, ct);
        return usuario is null ? NotFound() : Ok(UsuarioResponse.De(usuario));
    }

    [HttpPost]
    [RequierePermiso("usuarios", "crear")]
    public async Task<ActionResult<int>> Crear(CrearUsuarioRequest request, CancellationToken ct)
    {
        var hash = passwordHasher.Hash(request.Password);
        var id = await usuarios.InsertarAsync(new UsuarioRequest(request.NombreUsuario, request.Email, hash, request.IdRol, request.IdEmpleado), ct);
        return CreatedAtAction(nameof(ObtenerPorId), new { id }, id);
    }

    [HttpPut("{id:int}")]
    [RequierePermiso("usuarios", "editar")]
    public async Task<IActionResult> Actualizar(int id, UsuarioUpdateRequest request, CancellationToken ct)
    {
        await usuarios.ActualizarAsync(id, request, ct);
        return NoContent();
    }

    [HttpDelete("{id:int}")]
    [RequierePermiso("usuarios", "eliminar")]
    public async Task<IActionResult> Desactivar(int id, CancellationToken ct)
    {
        await usuarios.DesactivarAsync(id, ct);
        return NoContent();
    }

    /// <summary>Cambio de password del propio usuario autenticado (verifica la actual antes de aceptar la nueva).</summary>
    [HttpPost("{id:int}/cambiar-password")]
    public async Task<IActionResult> CambiarPassword(int id, CambiarPasswordRequest request, CancellationToken ct)
    {
        var claimId = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (claimId != id.ToString()) return Forbid();

        var usuario = await usuarios.ObtenerPorIdAsync(id, ct);
        if (usuario is null) return NotFound();
        if (!passwordHasher.Verify(request.PasswordActual, usuario.PasswordHash))
            return BadRequest(new { mensaje = "La contrasena actual no coincide." });

        await usuarios.CambiarPasswordAsync(id, passwordHasher.Hash(request.PasswordNueva), ct);
        return NoContent();
    }
}

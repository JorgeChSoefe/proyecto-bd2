using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Api.Auth;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Api.Controllers;

[ApiController]
[Route("api/auth")]
public sealed class AuthController(
    IUsuarioRepository usuarios,
    IPasswordHasher passwordHasher,
    IJwtTokenService jwtTokenService) : ControllerBase
{
    /// <summary>
    /// sp_Usuario_Autenticar retorna la fila (incluye password_hash); esta
    /// capa verifica con BCrypt -- la BD nunca decide si la password matchea.
    /// Si es correcta, arma el JWT con un claim "perm" por cada fila de
    /// vw_UsuarioPermisos y actualiza ultimo_acceso.
    /// </summary>
    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request, CancellationToken ct)
    {
        var usuario = await usuarios.AutenticarAsync(request.NombreUsuario, ct);
        if (usuario is null || !usuario.Activo || !passwordHasher.Verify(request.Password, usuario.PasswordHash))
            return Unauthorized(new { mensaje = "Usuario o contrasena invalidos." });

        var permisos = await usuarios.ObtenerPermisosAsync(usuario.IdUsuario, ct);
        var (token, expiraEn) = jwtTokenService.GenerarToken(usuario, permisos);

        await usuarios.ActualizarUltimoAccesoAsync(usuario.IdUsuario, ct);

        return Ok(new LoginResponse(token, expiraEn, usuario.IdUsuario, usuario.NombreUsuario, usuario.NombreRol ?? string.Empty));
    }
}

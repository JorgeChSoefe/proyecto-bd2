using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Application.Dtos;

/// <summary>Alta de usuario. PasswordHash ya viene hasheado con BCrypt (la Api lo genera antes de llamar al repo).</summary>
public sealed record UsuarioRequest(string NombreUsuario, string? Email, string PasswordHash, int IdRol, int? IdEmpleado);

public sealed record UsuarioUpdateRequest(string? Email, int IdRol, int? IdEmpleado);

public sealed record LoginRequest(string NombreUsuario, string Password);

/// <summary>Respuesta de login: token + datos minimos del usuario para que el front pinte la sesion.</summary>
public sealed record LoginResponse(string Token, DateTime ExpiraEn, int IdUsuario, string NombreUsuario, string NombreRol);

public sealed record CambiarPasswordRequest(string PasswordActual, string PasswordNueva);

/// <summary>
/// Forma de salida para GET /api/usuarios[/{id}] -- nunca incluye
/// PasswordHash. La entidad Usuario de Domain SI lo trae (lo necesita
/// AuthController para verificar el login); este DTO es el unico shape que
/// sale hacia el cliente HTTP.
/// </summary>
public sealed record UsuarioResponse(
    int IdUsuario, string NombreUsuario, string? Email, bool Activo,
    DateTime? UltimoAcceso, DateTime CreadoEn, int IdRol, string? NombreRol, int? IdEmpleado)
{
    public static UsuarioResponse De(Usuario u) => new(
        u.IdUsuario, u.NombreUsuario, u.Email, u.Activo, u.UltimoAcceso, u.CreadoEn, u.IdRol, u.NombreRol, u.IdEmpleado);
}

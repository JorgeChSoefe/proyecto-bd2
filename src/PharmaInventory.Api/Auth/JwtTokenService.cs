using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.Tokens;
using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Api.Auth;

/// <summary>
/// Arma el JWT tras un login exitoso: claims de identidad + un claim "perm"
/// por cada fila de vw_UsuarioPermisos (ver sp_Usuario_ObtenerPermisos).
/// PermisoAuthorizationHandler revisa esos claims contra
/// [RequierePermiso("modulo","accion")].
/// </summary>
public sealed class JwtTokenService(IOptions<JwtOptions> options) : IJwtTokenService
{
    public (string Token, DateTime ExpiraEn) GenerarToken(Usuario usuario, IReadOnlyList<Permiso> permisos)
    {
        var opts = options.Value;

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, usuario.IdUsuario.ToString()),
            new("nombre_usuario", usuario.NombreUsuario),
            new("id_rol", usuario.IdRol.ToString()),
            new(ClaimTypes.Role, usuario.NombreRol ?? string.Empty),
        };
        claims.AddRange(permisos.Select(p => new Claim("perm", $"{p.Modulo}:{p.Accion}")));

        var signingKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(opts.SigningKey));
        var credenciales = new SigningCredentials(signingKey, SecurityAlgorithms.HmacSha256);
        var expiraEn = DateTime.UtcNow.AddMinutes(opts.ExpiracionMinutos);

        var token = new JwtSecurityToken(
            issuer: opts.Issuer,
            audience: opts.Audience,
            claims: claims,
            expires: expiraEn,
            signingCredentials: credenciales);

        return (new JwtSecurityTokenHandler().WriteToken(token), expiraEn);
    }
}

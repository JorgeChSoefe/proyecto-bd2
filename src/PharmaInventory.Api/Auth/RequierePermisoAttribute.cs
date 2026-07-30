using Microsoft.AspNetCore.Authorization;

namespace PharmaInventory.Api.Auth;

/// <summary>
/// [RequierePermiso("inventario", "ajustar")] -- exige que el JWT traiga un
/// claim "perm" con valor "inventario:ajustar" (ver vw_UsuarioPermisos /
/// JwtTokenService). La politica la resuelve PermisoPolicyProvider en
/// tiempo real, no hace falta registrar cada combinacion modulo/accion.
/// </summary>
public sealed class RequierePermisoAttribute(string modulo, string accion)
    : AuthorizeAttribute($"{PermisoPolicyProvider.Prefijo}{modulo}:{accion}");

namespace PharmaInventory.Domain.Entities;

/// <summary>Tabla roles.</summary>
public class Rol
{
    public int IdRol { get; set; }
    public string NombreRol { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
}

/// <summary>Tabla permisos. (modulo, accion) identifica el permiso, ver vw_UsuarioPermisos.</summary>
public class Permiso
{
    public int IdPermiso { get; set; }
    public string Modulo { get; set; } = string.Empty;
    public string Accion { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
}

/// <summary>Tabla empleados.</summary>
public class Empleado
{
    public int IdEmpleado { get; set; }
    public string NombreCompleto { get; set; } = string.Empty;
    public string? Cargo { get; set; }
    public string? Email { get; set; }
}

/// <summary>
/// Tabla usuarios. PasswordHash nunca sale de Infrastructure hacia la Api
/// (los DTOs de Application no lo incluyen); solo se usa dentro del repo de
/// autenticacion para verificar con BCrypt.
/// </summary>
public class Usuario
{
    public int IdUsuario { get; set; }
    public string NombreUsuario { get; set; } = string.Empty;
    public string? Email { get; set; }
    public string PasswordHash { get; set; } = string.Empty;
    public int IdRol { get; set; }
    public string? NombreRol { get; set; }
    public int? IdEmpleado { get; set; }
    public bool Activo { get; set; }
    public DateTime? UltimoAcceso { get; set; }
    public DateTime CreadoEn { get; set; }
}

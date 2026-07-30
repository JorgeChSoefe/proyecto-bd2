namespace PharmaInventory.Application.Dtos;

// DTOs de entrada para los catalogos simples. La forma de salida reutiliza
// directamente la entidad de Domain (Rol, Permiso, Empleado, Categoria, ...)
// porque son passthrough 1:1 de sus vistas sin campos sensibles que ocultar
// -- introducir un DTO de salida paralelo aqui seria puro ceremonial. Donde
// el wire shape SI diverge de la entidad (Usuario, Venta, Compra, Receta,
// Auth) hay DTOs de salida dedicados en sus propios archivos.

public sealed record RolRequest(string NombreRol, string? Descripcion);

public sealed record PermisoRequest(string Modulo, string Accion, string? Descripcion);

public sealed record EmpleadoRequest(string NombreCompleto, string? Cargo, string? Email);

public sealed record CategoriaRequest(string NombreCategoria, string? Descripcion);

public sealed record ProveedorRequest(string NombreEmpresa, string? ContactoNombre, string? Telefono, string? Email);

public sealed record LaboratorioRequest(string Nombre, string? PaisOrigen, string? Telefono, string? Email, string? SitioWeb);

public sealed record PrincipioActivoRequest(string NombreInn, string? GrupoTerapeutico, string? Descripcion);

public sealed record PresentacionRequest(string Forma, string? UnidadMedida);

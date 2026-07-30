namespace PharmaInventory.Domain.Entities;

/// <summary>Tabla categorias.</summary>
public class Categoria
{
    public int IdCategoria { get; set; }
    public string NombreCategoria { get; set; } = string.Empty;
    public string? Descripcion { get; set; }
}

/// <summary>Tabla proveedores.</summary>
public class Proveedor
{
    public int IdProveedor { get; set; }
    public string NombreEmpresa { get; set; } = string.Empty;
    public string? ContactoNombre { get; set; }
    public string? Telefono { get; set; }
    public string? Email { get; set; }
}

/// <summary>Tabla laboratorios.</summary>
public class Laboratorio
{
    public int IdLaboratorio { get; set; }
    public string Nombre { get; set; } = string.Empty;
    public string? PaisOrigen { get; set; }
    public string? Telefono { get; set; }
    public string? Email { get; set; }
    public string? SitioWeb { get; set; }
}

/// <summary>Tabla principios_activos (catalogo INN/DCI).</summary>
public class PrincipioActivo
{
    public int IdPrincipio { get; set; }
    public string NombreInn { get; set; } = string.Empty;
    public string? GrupoTerapeutico { get; set; }
    public string? Descripcion { get; set; }
}

/// <summary>Tabla presentaciones (formas farmaceuticas).</summary>
public class Presentacion
{
    public int IdPresentacion { get; set; }
    public string Forma { get; set; } = string.Empty;
    public string? UnidadMedida { get; set; }
}

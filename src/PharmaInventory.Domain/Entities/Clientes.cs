namespace PharmaInventory.Domain.Entities;

/// <summary>Tabla clientes.</summary>
public class Cliente
{
    public int IdCliente { get; set; }
    public string NombreCompleto { get; set; } = string.Empty;
    public string Identificacion { get; set; } = string.Empty;
    public string? Telefono { get; set; }
    public DateTime? FechaNacimiento { get; set; }
    public string? Email { get; set; }
}

/// <summary>Tabla recetas.</summary>
public class Receta
{
    public int IdReceta { get; set; }
    public string NumeroReceta { get; set; } = string.Empty;
    public int IdCliente { get; set; }
    public string? NombreMedico { get; set; }
    public string? NumColegioMedico { get; set; }
    public DateTime FechaEmision { get; set; }
    public DateTime? FechaVencimiento { get; set; }
    public bool Dispensada { get; set; }
    public int? IdVenta { get; set; }
    public string? Notas { get; set; }
    public DateTime CreadoEn { get; set; }

    // Campo resuelto por join (vw_RecetasPendientes).
    public string? NombreCliente { get; set; }
}

/// <summary>Tabla detalle_recetas.</summary>
public class DetalleReceta
{
    public int IdDetalle { get; set; }
    public int IdReceta { get; set; }
    public int IdProducto { get; set; }
    public int CantidadPrescrita { get; set; }
    public string? Dosis { get; set; }
    public string? DuracionTratamiento { get; set; }
    public bool Dispensada { get; set; }

    // Campo resuelto por join (sp_Receta_ObtenerPorId).
    public string? NombreProducto { get; set; }
}

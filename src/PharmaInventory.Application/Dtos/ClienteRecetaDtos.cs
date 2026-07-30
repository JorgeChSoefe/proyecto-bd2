using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Application.Dtos;

public sealed record ClienteRequest(string NombreCompleto, string Identificacion, string? Telefono, DateTime? FechaNacimiento, string? Email);

/// <summary>Una linea del TVP dbo.TipoDetalleReceta.</summary>
public sealed record LineaRecetaRequest(int IdProducto, int CantidadPrescrita, string? Dosis, string? DuracionTratamiento);

public sealed record RecetaRequest(
    string NumeroReceta, int IdCliente, string? NombreMedico, string? NumColegioMedico,
    DateTime FechaEmision, DateTime? FechaVencimiento, string? Notas,
    IReadOnlyList<LineaRecetaRequest> Detalle);

/// <summary>Resultado de sp_Receta_ObtenerPorId: cabecera + lineas de detalle_recetas.</summary>
public sealed record RecetaDetalleDto(Receta Receta, IReadOnlyList<DetalleReceta> Lineas);

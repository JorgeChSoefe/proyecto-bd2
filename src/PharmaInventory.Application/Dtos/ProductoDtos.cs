using PharmaInventory.Domain.Entities;
using PharmaInventory.Domain.Enums;

namespace PharmaInventory.Application.Dtos;

public sealed record ProductoRequest(
    string Nombre, string? NombreGenerico, string? CodigoSku, string? CodigoBarras,
    decimal PrecioCosto, decimal PrecioVenta, int StockMinimo, bool RequiereReceta,
    int? IdCategoria, int? IdProveedor, int? IdLaboratorio, int? IdPresentacion);

/// <summary>
/// Nunca incluye StockActual/PrecioPromedioPond: esos campos son de solo
/// lectura para la Api, solo los mueve sp_Kardex_RegistrarMovimiento (regla
/// de oro de CLAUDE.md seccion 5.3).
/// </summary>
public sealed record ProductoUpdateRequest(
    string Nombre, string? NombreGenerico, string? CodigoSku, string? CodigoBarras,
    decimal PrecioCosto, decimal PrecioVenta, int StockMinimo, bool RequiereReceta,
    int? IdCategoria, int? IdProveedor, int? IdLaboratorio, int? IdPresentacion);

/// <summary>Resultado de sp_Producto_ObtenerPorId: cabecera + ficha clinica (si existe) + principios activos.</summary>
public sealed record ProductoDetalleDto(Producto Producto, Medicamento? Medicamento, IReadOnlyList<MedicamentoPrincipio> PrincipiosActivos);

public sealed record MedicamentoRequest(
    int IdProducto, string? Concentracion, ViaAdministracion ViaAdministracion,
    string? CondicionesAlmacenamiento, bool Controlado, string? NumeroRegistroSanitario,
    string? Indicaciones, string? Contraindicaciones, string? EfectosSecundarios, string? Interacciones);

public sealed record MedicamentoUpdateRequest(
    string? Concentracion, ViaAdministracion ViaAdministracion, string? CondicionesAlmacenamiento,
    bool Controlado, string? NumeroRegistroSanitario, string? Indicaciones,
    string? Contraindicaciones, string? EfectosSecundarios, string? Interacciones);

public sealed record MedicamentoPrincipioRequest(int IdMedicamento, int IdPrincipio, decimal CantidadPorDosis, string Unidad);

/// <summary>
/// Una fila de vw_ProductosMedicamentos: ficha tecnica completa (producto +
/// medicamento + un principio activo). Un medicamento con N principios
/// activos produce N filas -- LEFT JOIN, por eso los campos de principio son
/// nullable. Forma larga (no posicional) para que Dapper la materialice por
/// propiedades -- ver nota en InventarioDtos.cs.
/// </summary>
public sealed record FichaMedicamentoDto
{
    public int IdProducto { get; init; }
    public string Nombre { get; init; } = string.Empty;
    public bool RequiereReceta { get; init; }
    public int IdMedicamento { get; init; }
    public string? Concentracion { get; init; }
    public ViaAdministracion ViaAdministracion { get; init; }
    public bool Controlado { get; init; }
    public string? NumeroRegistroSanitario { get; init; }
    public string? CondicionesAlmacenamiento { get; init; }
    public string? NombreInn { get; init; }
    public string? GrupoTerapeutico { get; init; }
    public decimal? CantidadPorDosis { get; init; }
    public string? Unidad { get; init; }
}

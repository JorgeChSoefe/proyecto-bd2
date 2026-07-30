namespace PharmaInventory.Domain.Exceptions;

/// <summary>
/// Base de las excepciones de negocio que se originan como THROW en un SP
/// (codigos 50000+, ver 05_Inventario_Kardex.sql etc). SqlErrorMapper en
/// Infrastructure traduce cada Number de SqlException a una de estas.
/// El controller/middleware las traduce a su vez a un status HTTP (ver
/// ExceptionHandlingMiddleware en la Api).
/// </summary>
public abstract class DomainException(string message) : Exception(message)
{
    /// <summary>Codigo de error SQL original (50000+) que origino la excepcion, si aplica.</summary>
    public int? SqlErrorNumber { get; init; }
}

/// <summary>Stock insuficiente para completar una venta o movimiento (50032, 50052).</summary>
public sealed class StockInsuficienteException(string message) : DomainException(message);

/// <summary>La receta no existe o esta vencida (50050).</summary>
public sealed class RecetaNoVigenteException(string message) : DomainException(message);

/// <summary>Uno o mas productos requieren receta medica vigente, o la receta no los cubre (50051, 50055, 50056).</summary>
public sealed class RecetaRequeridaException(string message) : DomainException(message);

/// <summary>codigo_sku o codigo_barras duplicado (50020, 50023), u otra llave natural duplicada (usuario, cliente, permiso, receta).</summary>
public sealed class ClaveDuplicadaException(string message) : DomainException(message);

/// <summary>Operacion no valida para el estado actual de la entidad (venta ya anulada, compra ya recibida, ventana de anulacion vencida, etc).</summary>
public sealed class EstadoInvalidoException(string message) : DomainException(message);

/// <summary>No se puede eliminar/modificar porque la entidad esta en uso por otra (FK protegida por el propio SP).</summary>
public sealed class EntidadEnUsoException(string message) : DomainException(message);

/// <summary>La entidad solicitada no existe.</summary>
public sealed class NoEncontradoException(string message) : DomainException(message);

/// <summary>El detalle enviado (TVP) no coincide con lo esperado por el SP (compras B4, recetas, etc).</summary>
public sealed class DetalleInvalidoException(string message) : DomainException(message);

/// <summary>Error de negocio sin mapeo especifico -- fallback para codigos 50000+ no catalogados.</summary>
public sealed class ReglaNegocioException(string message) : DomainException(message);

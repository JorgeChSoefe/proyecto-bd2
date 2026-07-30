using Microsoft.Data.SqlClient;
using PharmaInventory.Domain.Exceptions;

namespace PharmaInventory.Infrastructure.Persistence;

/// <summary>
/// Traduce el Number de un THROW de SQL (rango 50000+, ver CLAUDE.md seccion
/// 2 y los .sql) a la excepcion tipada de Domain correspondiente. Es el unico
/// lugar del proyecto que conoce estos codigos -- todos los repos pasan por
/// RepositoryBase, que solo llama a Map() cuando ex.Number &gt;= 50000.
///
/// Un Number fuera del rango 50000+ (timeout, deadlock, columna invalida,
/// login fallido, etc) NO es un error de negocio: RepositoryBase ni siquiera
/// lo atrapa (filtro "when"), asi que se propaga intacto -- stack trace
/// original completo -- para que el middleware lo trate como 500 con su
/// detalle real en el log.
/// </summary>
public static class SqlErrorMapper
{
    // SqlException no tiene constructor publico (ni siquiera para tests),
    // asi que la logica de mapeo vive en el overload (int, string) --
    // trivialmente testeable sin reflection fragil contra tipos internos de
    // Microsoft.Data.SqlClient. El overload real solo desempaqueta.
    public static DomainException Map(SqlException ex) => Map(ex.Number, ex.Message);

    public static DomainException Map(int number, string message) => number switch
    {
        50001 => new NoEncontradoException("El rol no existe."),
        50002 => new EntidadEnUsoException("No se puede eliminar el rol: tiene usuarios asignados."),
        50003 => new EntidadEnUsoException("No se puede eliminar: el empleado tiene un usuario asociado."),
        50004 => new ClaveDuplicadaException("El nombre de usuario ya existe."),
        50005 => new ClaveDuplicadaException("Ya existe un permiso con ese modulo y accion."),
        50006 => new NoEncontradoException("El permiso no existe."),
        50007 => new EntidadEnUsoException("No se puede eliminar: el permiso esta asignado a uno o mas roles."),
        50010 => new EntidadEnUsoException("No se puede eliminar: hay productos con esta categoria."),
        50011 => new EntidadEnUsoException("No se puede eliminar: hay productos de este proveedor."),
        50012 => new EntidadEnUsoException("No se puede eliminar: hay productos de este laboratorio."),
        50013 => new EntidadEnUsoException("No se puede eliminar: esta en uso por medicamentos."),
        50014 => new EntidadEnUsoException("No se puede eliminar: hay productos con esta presentacion."),
        50020 => new ClaveDuplicadaException("El codigo SKU ya existe."),
        50021 => new EntidadEnUsoException("No se puede eliminar: el producto tiene movimientos de inventario."),
        50022 => new ClaveDuplicadaException("Este producto ya tiene ficha de medicamento."),
        50023 => new ClaveDuplicadaException("El codigo de barras ya existe."),
        50030 => new ReglaNegocioException("Tipo de movimiento invalido."),
        50031 => new NoEncontradoException("Producto no existe."),
        50032 => new StockInsuficienteException("Stock insuficiente para el movimiento."),
        50033 => new ReglaNegocioException("Debe indicar cantidad_entrada o cantidad_salida (exactamente una, mayor a cero)."),
        50034 => new ReglaNegocioException("La cantidad del ajuste no puede ser cero."),
        50040 => new ClaveDuplicadaException("Ya existe un cliente con esa identificacion."),
        50041 => new EntidadEnUsoException("No se puede eliminar: el cliente tiene ventas registradas."),
        50050 => new RecetaNoVigenteException("La receta no existe o esta vencida."),
        50051 => new RecetaRequeridaException("Uno o mas productos requieren receta medica vigente."),
        50052 => new StockInsuficienteException(message),
        50053 => new NoEncontradoException("La venta no existe."),
        50054 => new EstadoInvalidoException("La venta ya esta anulada."),
        50055 => new RecetaRequeridaException("La receta no pertenece al cliente indicado."),
        50056 => new RecetaRequeridaException("La receta no cubre alguno de los productos controlados/con receta requerida en la cantidad solicitada."),
        50057 => new EstadoInvalidoException("La venta ya no se puede anular: supera la ventana de dias permitida."),
        50060 => new NoEncontradoException("La compra no existe."),
        50061 => new EstadoInvalidoException("Solo se pueden recibir compras en estado pendiente."),
        50062 => new NoEncontradoException("La compra no existe."),
        50063 => new EstadoInvalidoException("Solo se pueden anular compras en estado pendiente (aun no recibidas)."),
        50064 => new DetalleInvalidoException("Cada linea del detalle debe indicar id_detalle (la fila real de detalle_compras a recibir)."),
        50065 => new DetalleInvalidoException("Alguna linea de detalle no existe, no pertenece a esta compra, o ya fue recibida."),
        50066 => new DetalleInvalidoException("El detalle enviado no cubre exactamente todas las lineas pendientes de la compra."),
        _ => new ReglaNegocioException(message),
    };
}

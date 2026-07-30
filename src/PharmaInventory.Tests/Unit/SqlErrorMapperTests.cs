using PharmaInventory.Domain.Exceptions;
using PharmaInventory.Infrastructure.Persistence;
using Xunit;

namespace PharmaInventory.Tests.Unit;

/// <summary>
/// SqlErrorMapper es el unico lugar que traduce THROW de SQL (50000+) a
/// excepciones de Domain -- si un codigo queda mal mapeado, el middleware le
/// pone el status HTTP equivocado sin que nada mas lo note. Usa el overload
/// Map(int, string) (ver SqlErrorMapper.cs) en vez de construir un
/// SqlException real -- ese tipo no tiene constructor publico y no vale la
/// pena depender de sus constructores internos (cambian entre versiones de
/// Microsoft.Data.SqlClient) solo para testear un switch.
/// </summary>
public class SqlErrorMapperTests
{
    [Theory]
    [InlineData(50001, typeof(NoEncontradoException))]
    [InlineData(50002, typeof(EntidadEnUsoException))]
    [InlineData(50004, typeof(ClaveDuplicadaException))]
    [InlineData(50007, typeof(EntidadEnUsoException))]
    [InlineData(50020, typeof(ClaveDuplicadaException))]
    [InlineData(50023, typeof(ClaveDuplicadaException))]
    [InlineData(50031, typeof(NoEncontradoException))]
    [InlineData(50032, typeof(StockInsuficienteException))]
    [InlineData(50040, typeof(ClaveDuplicadaException))]
    [InlineData(50050, typeof(RecetaNoVigenteException))]
    [InlineData(50051, typeof(RecetaRequeridaException))]
    [InlineData(50052, typeof(StockInsuficienteException))]
    [InlineData(50054, typeof(EstadoInvalidoException))]
    [InlineData(50055, typeof(RecetaRequeridaException))]
    [InlineData(50056, typeof(RecetaRequeridaException))]
    [InlineData(50057, typeof(EstadoInvalidoException))]
    [InlineData(50061, typeof(EstadoInvalidoException))]
    [InlineData(50064, typeof(DetalleInvalidoException))]
    [InlineData(50065, typeof(DetalleInvalidoException))]
    [InlineData(50066, typeof(DetalleInvalidoException))]
    [InlineData(59999, typeof(ReglaNegocioException))] // codigo 50000+ sin catalogar -> fallback, no se pierde
    public void Map_TraduceCadaCodigoAlTipoCorrecto(int numeroSql, Type tipoEsperado)
    {
        var resultado = SqlErrorMapper.Map(numeroSql, "mensaje de prueba");

        Assert.IsType(tipoEsperado, resultado);
    }

    [Fact]
    public void Map_ReenviaElMensajeDinamicoDelSpParaCodigosQueLoNecesitan()
    {
        // 50052 lo lanza sp_Venta_Registrar con un mensaje armado en runtime
        // (incluye producto/cantidades) -- el mapper no debe reemplazarlo
        // por uno generico, o se pierde el detalle util para el cliente.
        var resultado = SqlErrorMapper.Map(50052, "Stock insuficiente para el producto id=3 (solicitado 999, disponible 5).");

        Assert.Contains("id=3", resultado.Message);
        Assert.Contains("disponible 5", resultado.Message);
    }

    [Fact]
    public void Map_CodigoFueraDeRangoDeNegocio_CaeEnReglaNegocioConMensajeOriginal()
    {
        var resultado = SqlErrorMapper.Map(50999, "mensaje no catalogado");

        Assert.IsType<ReglaNegocioException>(resultado);
        Assert.Equal("mensaje no catalogado", resultado.Message);
    }
}

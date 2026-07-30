using System.Data;
using PharmaInventory.Domain.Enums;
using PharmaInventory.Infrastructure.Persistence;
using Xunit;

namespace PharmaInventory.Tests.Unit;

/// <summary>
/// StringEnumTypeHandler&lt;T&gt; convierte enums PascalCase de Domain hacia/desde
/// el snake_case que exigen los CHECK constraints (ver 10_Schema_Tablas.sql).
/// Si el round-trip se rompe para algun valor, un INSERT/UPDATE le manda a
/// SQL Server un string que no matchea ningun CHECK y el SP tira una
/// excepcion de constraint en vez del THROW de negocio esperado.
/// </summary>
public class StringEnumTypeHandlerTests
{
#pragma warning disable CS8766, CS8767 // fixture minimo solo para pasarle un IDbDataParameter al handler; la nulabilidad exacta de estas props no importa para el test.
    private sealed class FakeParameter : IDbDataParameter
    {
        public DbType DbType { get; set; }
        public object? Value { get; set; }
        public ParameterDirection Direction { get; set; }
        public bool IsNullable => true;
        public string? ParameterName { get; set; } = string.Empty;
        public string? SourceColumn { get; set; } = string.Empty;
        public DataRowVersion SourceVersion { get; set; }
        public byte Precision { get; set; }
        public byte Scale { get; set; }
        public int Size { get; set; }
    }
#pragma warning restore CS8766, CS8767

    public static TheoryData<TipoMovimientoKardex, string> ValoresKardex => new()
    {
        { TipoMovimientoKardex.Entrada, "entrada" },
        { TipoMovimientoKardex.Salida, "salida" },
        { TipoMovimientoKardex.Ajuste, "ajuste" },
    };

    [Theory]
    [MemberData(nameof(ValoresKardex))]
    public void SetValue_ConvierteAlSnakeCaseExactoDelCheckConstraint(TipoMovimientoKardex valor, string esperado)
    {
        var handler = new StringEnumTypeHandler<TipoMovimientoKardex>();
        var parametro = new FakeParameter();

        handler.SetValue(parametro, valor);

        Assert.Equal(esperado, parametro.Value);
        Assert.Equal(DbType.String, parametro.DbType);
    }

    [Theory]
    [MemberData(nameof(ValoresKardex))]
    public void Parse_HaceElRoundTripInversoCorrectamente(TipoMovimientoKardex esperado, string snakeCase)
    {
        var handler = new StringEnumTypeHandler<TipoMovimientoKardex>();

        var resultado = handler.Parse(snakeCase);

        Assert.Equal(esperado, resultado);
    }

    [Theory]
    [InlineData(TipoAlerta.VencimientoProximo, "vencimiento_proximo")]
    [InlineData(TipoAlerta.StockMinimo, "stock_minimo")]
    [InlineData(TipoAlerta.LoteAgotado, "lote_agotado")]
    public void FuncionaIgualParaEnumsConMultiplesPalabras(TipoAlerta valor, string esperado)
    {
        var handler = new StringEnumTypeHandler<TipoAlerta>();
        var parametro = new FakeParameter();

        handler.SetValue(parametro, valor);
        Assert.Equal(esperado, parametro.Value);

        var vuelta = handler.Parse(esperado);
        Assert.Equal(valor, vuelta);
    }

    [Theory]
    [InlineData(EstadoVenta.Pendiente, "pendiente")]
    [InlineData(EstadoVenta.Completada, "completada")]
    [InlineData(EstadoVenta.Anulada, "anulada")]
    public void EstadoVenta_MatcheaLosValoresDelCheckDeVentas(EstadoVenta valor, string esperado)
    {
        var handler = new StringEnumTypeHandler<EstadoVenta>();
        var parametro = new FakeParameter();
        handler.SetValue(parametro, valor);
        Assert.Equal(esperado, parametro.Value);
    }
}

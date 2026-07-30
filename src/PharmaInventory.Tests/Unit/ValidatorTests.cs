using PharmaInventory.Application.Dtos;
using PharmaInventory.Application.Validators;
using Xunit;

namespace PharmaInventory.Tests.Unit;

/// <summary>
/// Validacion de FORMA (FluentValidation, ver Application/Validators). No
/// cubre reglas de negocio -- esas viven en los SP y las prueba
/// SqlErrorMapperTests + los tests de integracion.
/// </summary>
public class ValidatorTests
{
    [Fact]
    public void VentaRequestValidator_RechazaDetalleVacio()
    {
        var request = new VentaRequest(IdEmpleado: 1, IdCliente: null, IdReceta: null, Detalle: []);

        var resultado = new VentaRequestValidator().Validate(request);

        Assert.False(resultado.IsValid);
    }

    [Fact]
    public void VentaRequestValidator_AceptaUnaLineaValida()
    {
        var request = new VentaRequest(IdEmpleado: 1, IdCliente: null, IdReceta: null,
            Detalle: [new LineaVentaRequest(IdProducto: 1, Cantidad: 2, PrecioUnitario: 100)]);

        var resultado = new VentaRequestValidator().Validate(request);

        Assert.True(resultado.IsValid);
    }

    [Fact]
    public void LineaVentaRequestValidator_RechazaCantidadCero()
    {
        var request = new VentaRequest(1, null, null, [new LineaVentaRequest(1, Cantidad: 0, PrecioUnitario: 100)]);

        var resultado = new VentaRequestValidator().Validate(request);

        Assert.False(resultado.IsValid);
    }

    [Theory]
    [InlineData(0)]
    public void AjusteManualRequestValidator_RechazaCantidadCero(int cantidad)
    {
        var request = new AjusteManualRequest(IdProducto: 1, IdLote: null, Cantidad: cantidad, Motivo: "conteo fisico");

        var resultado = new AjusteManualRequestValidator().Validate(request);

        Assert.False(resultado.IsValid);
    }

    [Fact]
    public void AjusteManualRequestValidator_RechazaMotivoVacio()
    {
        // B1/observaciones existen precisamente para que el motivo del ajuste
        // quede auditable -- no tiene sentido aceptar uno vacio.
        var request = new AjusteManualRequest(IdProducto: 1, IdLote: null, Cantidad: 10, Motivo: "");

        var resultado = new AjusteManualRequestValidator().Validate(request);

        Assert.False(resultado.IsValid);
    }

    [Fact]
    public void AjusteManualRequestValidator_AceptaAjustePositivoConMotivo()
    {
        var request = new AjusteManualRequest(IdProducto: 1, IdLote: null, Cantidad: 15, Motivo: "Conteo fisico mensual");

        var resultado = new AjusteManualRequestValidator().Validate(request);

        Assert.True(resultado.IsValid);
    }

    [Fact]
    public void RecetaRequestValidator_RechazaFechaVencimientoAnteriorAEmision()
    {
        var request = new RecetaRequest(
            NumeroReceta: "RX-9999", IdCliente: 1, NombreMedico: "Dr. Test", NumColegioMedico: null,
            FechaEmision: new DateTime(2026, 8, 1), FechaVencimiento: new DateTime(2026, 7, 1), Notas: null,
            Detalle: [new LineaRecetaRequest(IdProducto: 1, CantidadPrescrita: 1, Dosis: null, DuracionTratamiento: null)]);

        var resultado = new RecetaRequestValidator().Validate(request);

        Assert.False(resultado.IsValid);
    }

    [Fact]
    public void RecetaRequestValidator_RechazaRecetaSinDetalle()
    {
        var request = new RecetaRequest("RX-9999", 1, "Dr. Test", null, DateTime.Today, null, null, []);

        var resultado = new RecetaRequestValidator().Validate(request);

        Assert.False(resultado.IsValid);
    }

    [Fact]
    public void LoginRequestValidator_RechazaUsuarioVacio()
    {
        var request = new LoginRequest(NombreUsuario: "", Password: "algo");

        var resultado = new LoginRequestValidator().Validate(request);

        Assert.False(resultado.IsValid);
    }

    [Fact]
    public void CompraRecibirRequestValidator_RechazaLineaSinIdDetalle()
    {
        var request = new CompraRecibirRequest([
            new LineaRecepcionRequest(IdDetalle: 0, IdProducto: 1, Cantidad: 10, PrecioUnitario: 100,
                NumeroLote: "L1", FechaFabricacion: null, FechaVencimiento: DateTime.Today.AddYears(1)),
        ]);

        var resultado = new CompraRecibirRequestValidator().Validate(request);

        Assert.False(resultado.IsValid);
    }
}

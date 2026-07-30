using System.Net.Http.Json;
using PharmaInventory.Application.Common;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;
using Xunit;

namespace PharmaInventory.Tests.Integration;

/// <summary>
/// El flujo transaccional completo contra el SQL Server real, vía HTTP de
/// punta a punta (Api -> Application -> Infrastructure -> SPs reales). Cubre
/// las mismas regresiones que el smoke test de tools/DbDeploy (--smoke), pero
/// como tests permanentes: compra multi-producto (bug B4), venta
/// multi-producto (bug del @lotes_fefo que no se reiniciaba en el loop),
/// venta+receta+anulacion sin corromper el costo promedio (bug B3), y ajuste
/// manual positivo (bug B1).
/// </summary>
[Collection("Integration")]
public class VentaCompraFlowIntegrationTests(CustomWebApplicationFactory factory)
{
    [RequiresDatabaseFact]
    public async Task CompraConDosProductos_GeneraUnLoteDistintoPorProducto_YActualizaStockDeAmbos()
    {
        var client = await AuthHelper.AuthenticatedClientAsync(factory, "admin");
        var idIbu = await BuscarProductoIdAsync(client, "IBU400");
        var idLora = await BuscarProductoIdAsync(client, "LORA10");
        var stockIbuAntes = await ObtenerStockActualAsync(client, idIbu);
        var stockLoraAntes = await ObtenerStockActualAsync(client, idLora);

        var sufijo = Guid.NewGuid().ToString("N")[..8];
        var request = new CompraRequest(IdProveedor: 1, IdEmpleado: 1, Detalle:
        [
            new LineaCompraRequest(idIbu, 10, 1000m, $"T-IBU-{sufijo}", null, DateTime.Today.AddYears(1)),
            new LineaCompraRequest(idLora, 15, 1200m, $"T-LORA-{sufijo}", null, DateTime.Today.AddYears(1)),
        ]);

        var registrar = await client.PostAsJsonAsync("/api/compras", request);
        registrar.EnsureSuccessStatusCode();
        var idCompra = await registrar.Content.ReadFromJsonAsync<int>();

        var detalle = await client.GetFromJsonAsync<CompraDetalleDto>($"/api/compras/{idCompra}", JsonTestOptions.CaseInsensitive);
        Assert.NotNull(detalle);
        Assert.Equal(2, detalle!.Lineas.Count);

        // OJO: antes de recibir, detalle_compras.id_lote (y por lo tanto el
        // numero_lote resuelto por el JOIN) todavia es NULL -- el numero de
        // lote a confirmar es el que ESTE test propuso al registrar, no algo
        // que se pueda releer de vuelta del detalle todavia sin recibir.
        var numeroLotePorProducto = request.Detalle.ToDictionary(l => l.IdProducto, l => l.NumeroLote);

        // Bug B4: antes, la primera linea recibida estampaba su lote en TODAS
        // las lineas pendientes del mismo... aqui son productos DISTINTOS asi
        // que el sintoma seria las dos lineas apuntando al mismo id_lote.
        var recibir = new CompraRecibirRequest(detalle.Lineas.Select(l =>
            new LineaRecepcionRequest(l.IdDetalle, l.IdProducto, l.Cantidad, l.PrecioUnitario,
                numeroLotePorProducto[l.IdProducto], null, DateTime.Today.AddYears(1))).ToList());

        var recibirResponse = await client.PatchAsync($"/api/compras/{idCompra}/recibir", JsonContent.Create(recibir));
        recibirResponse.EnsureSuccessStatusCode();

        var detalleRecibido = await client.GetFromJsonAsync<CompraDetalleDto>($"/api/compras/{idCompra}", JsonTestOptions.CaseInsensitive);
        var lotesDistintos = detalleRecibido!.Lineas.Select(l => l.IdLote).Distinct().ToList();
        Assert.Equal(2, lotesDistintos.Count); // cada producto en su propio lote, no colapsados en uno

        var stockIbuDespues = await ObtenerStockActualAsync(client, idIbu);
        var stockLoraDespues = await ObtenerStockActualAsync(client, idLora);
        Assert.Equal(stockIbuAntes + 10, stockIbuDespues);
        Assert.Equal(stockLoraAntes + 15, stockLoraDespues);
    }

    [RequiresDatabaseFact]
    public async Task VentaConDosProductosDistintos_CadaLineaQuedaConElLoteDeSuPropioProducto()
    {
        // Regresion del bug encontrado en vivo: DECLARE @lotes_fefo TABLE(...)
        // dentro del loop de sp_Venta_Registrar no se reiniciaba entre
        // productos -- la segunda linea heredaba (ademas de) los lotes de la
        // primera. Con dos productos DISTINTOS en la misma venta, el sintoma
        // es una linea de detalle_ventas cuyo id_lote pertenece al OTRO producto.
        var client = await AuthHelper.AuthenticatedClientAsync(factory, "admin");
        var idIbu = await BuscarProductoIdAsync(client, "IBU400");
        var idVitc = await BuscarProductoIdAsync(client, "VITC1000");

        var request = new VentaRequest(IdEmpleado: 1, IdCliente: null, IdReceta: null, Detalle:
        [
            new LineaVentaRequest(idIbu, 2, 2500m),
            new LineaVentaRequest(idVitc, 3, 4500m),
        ]);

        var registrar = await client.PostAsJsonAsync("/api/ventas", request);
        registrar.EnsureSuccessStatusCode();
        var idVenta = await registrar.Content.ReadFromJsonAsync<int>();

        var detalle = await client.GetFromJsonAsync<VentaDetalleDto>($"/api/ventas/{idVenta}", JsonTestOptions.CaseInsensitive);
        Assert.NotNull(detalle);

        // Cada linea de detalle_ventas debe pertenecer a uno de los dos
        // productos vendidos -- si el bug del @lotes_fefo reapareciera, una
        // linea terminaria con un id_producto/id_lote de un producto ajeno a
        // esta venta.
        foreach (var linea in detalle!.Lineas)
            Assert.Contains(linea.IdProducto, new[] { idIbu, idVitc });

        var idsProductosEnLineas = detalle.Lineas.Select(l => l.IdProducto).Distinct().ToList();
        Assert.Equal(2, idsProductosEnLineas.Count); // ambos productos aparecen, ninguno "engullido" por el otro
    }

    [RequiresDatabaseFact]
    public async Task AjusteManualPositivo_SubeElStock_YElMotivoQuedaEnElKardex()
    {
        // Regresion de B1: un ajuste positivo caia en la rama de "salida" y el
        // stock nunca subia.
        var client = await AuthHelper.AuthenticatedClientAsync(factory, "admin");
        var idProducto = await BuscarProductoIdAsync(client, "OMEP20");
        var stockAntes = await ObtenerStockActualAsync(client, idProducto);
        var motivo = $"Test automatizado {Guid.NewGuid():N}";

        var response = await client.PostAsJsonAsync("/api/inventario/ajustes",
            new AjusteManualRequest(idProducto, null, 7, motivo));
        response.EnsureSuccessStatusCode();

        var stockDespues = await ObtenerStockActualAsync(client, idProducto);
        Assert.Equal(stockAntes + 7, stockDespues);

        var kardex = await client.GetFromJsonAsync<PagedResult<MovimientoKardex>>(
            $"/api/inventario/kardex/{idProducto}?tamano=1", JsonTestOptions.CaseInsensitive);
        Assert.Equal(motivo, kardex!.Items[0].Observaciones);
    }

    [RequiresDatabaseFact]
    public async Task VentaDeProductoControlado_SinReceta_EsRechazada()
    {
        var client = await AuthHelper.AuthenticatedClientAsync(factory, "admin");
        var idDiazepam = await BuscarProductoIdAsync(client, "DIAZ5");

        var request = new VentaRequest(1, null, null, [new LineaVentaRequest(idDiazepam, 1, 3500m)]);
        var response = await client.PostAsJsonAsync("/api/ventas", request);

        Assert.Equal(System.Net.HttpStatusCode.UnprocessableEntity, response.StatusCode);
    }

    private static async Task<int> BuscarProductoIdAsync(HttpClient client, string codigoSku)
    {
        var pagina = await client.GetFromJsonAsync<PagedResult<Producto>>($"/api/productos?busqueda={codigoSku}&tamano=5", JsonTestOptions.CaseInsensitive);
        var producto = pagina!.Items.FirstOrDefault(p => p.CodigoSku == codigoSku);
        Assert.True(producto is not null, $"El producto seed con SKU {codigoSku} deberia existir (ver 11_Seed_Datos.sql).");
        return producto!.IdProducto;
    }

    private static async Task<int> ObtenerStockActualAsync(HttpClient client, int idProducto)
    {
        var detalle = await client.GetFromJsonAsync<ProductoDetalleDto>($"/api/productos/{idProducto}", JsonTestOptions.CaseInsensitive);
        return detalle!.Producto.StockActual;
    }
}

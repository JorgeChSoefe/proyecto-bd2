using PharmaInventory.Application.Abstractions;

namespace PharmaInventory.Api.Services;

/// <summary>
/// Job periodico que invoca sp_Alerta_GenerarPorStockMinimo y
/// sp_Alerta_GenerarPorVencimiento (CLAUDE.md seccion 5.5: las alertas NUNCA
/// se calculan en tiempo real en el front, siempre las genera un job). Corre
/// una vez al arrancar y luego cada IntervaloMinutos.
/// </summary>
public sealed class AlertasBackgroundService(
    IServiceScopeFactory scopeFactory,
    IConfiguration configuration,
    ILogger<AlertasBackgroundService> logger) : BackgroundService
{
    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        var intervalo = TimeSpan.FromMinutes(configuration.GetValue("AlertasBackgroundService:IntervaloMinutos", 60));
        var diasAnticipacion = configuration.GetValue("AlertasBackgroundService:DiasAnticipacionVencimiento", 30);

        using var timer = new PeriodicTimer(intervalo);
        do
        {
            try
            {
                using var scope = scopeFactory.CreateScope();
                var alertas = scope.ServiceProvider.GetRequiredService<IAlertaRepository>();
                await alertas.GenerarPorStockMinimoAsync(stoppingToken);
                await alertas.GenerarPorVencimientoAsync(diasAnticipacion, stoppingToken);
                logger.LogInformation("AlertasBackgroundService: ciclo de generacion de alertas completado.");
            }
            catch (Exception ex)
            {
                logger.LogError(ex, "AlertasBackgroundService: fallo generando alertas.");
            }
        } while (await timer.WaitForNextTickAsync(stoppingToken));
    }
}

using System.Net;
using FluentValidation;
using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Domain.Exceptions;

namespace PharmaInventory.Api.Middleware;

/// <summary>
/// Traduce las excepciones tipadas de Domain (originadas en un THROW de SP y
/// mapeadas por SqlErrorMapper en Infrastructure) a ProblemDetails con el
/// status HTTP correcto. Cualquier excepcion no reconocida cae a 500 y se
/// loguea completa -- nunca se expone su detalle interno al cliente.
/// </summary>
public sealed class ExceptionHandlingMiddleware(RequestDelegate next, ILogger<ExceptionHandlingMiddleware> logger)
{
    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await next(context);
        }
        catch (Exception ex)
        {
            await HandleAsync(context, ex);
        }
    }

    private async Task HandleAsync(HttpContext context, Exception ex)
    {
        var (status, title) = ex switch
        {
            StockInsuficienteException => (HttpStatusCode.Conflict, "Stock insuficiente"),
            ClaveDuplicadaException => (HttpStatusCode.Conflict, "Clave duplicada"),
            EntidadEnUsoException => (HttpStatusCode.Conflict, "Entidad en uso"),
            EstadoInvalidoException => (HttpStatusCode.Conflict, "Estado invalido para la operacion"),
            NoEncontradoException => (HttpStatusCode.NotFound, "No encontrado"),
            RecetaNoVigenteException => (HttpStatusCode.UnprocessableEntity, "Receta no vigente"),
            RecetaRequeridaException => (HttpStatusCode.UnprocessableEntity, "Receta requerida"),
            DetalleInvalidoException => (HttpStatusCode.BadRequest, "Detalle invalido"),
            ReglaNegocioException => (HttpStatusCode.UnprocessableEntity, "Regla de negocio"),
            ValidationException => (HttpStatusCode.BadRequest, "Error de validacion"),
            _ => (HttpStatusCode.InternalServerError, "Error interno"),
        };

        if (status == HttpStatusCode.InternalServerError)
            logger.LogError(ex, "Error no controlado en {Path}", context.Request.Path);
        else
            logger.LogInformation("{ExceptionType} en {Path}: {Message}", ex.GetType().Name, context.Request.Path, ex.Message);

        var problem = new ProblemDetails
        {
            Status = (int)status,
            Title = title,
            Detail = status == HttpStatusCode.InternalServerError ? "Ocurrio un error inesperado." : ex.Message,
            Instance = context.Request.Path,
        };

        if (ex is ValidationException validationEx)
        {
            problem.Extensions["errores"] = validationEx.Errors
                .GroupBy(e => e.PropertyName)
                .ToDictionary(g => g.Key, g => g.Select(e => e.ErrorMessage).ToArray());
        }

        context.Response.StatusCode = (int)status;
        context.Response.ContentType = "application/problem+json";
        await context.Response.WriteAsJsonAsync(problem);
    }
}

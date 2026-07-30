using FluentValidation;
using Microsoft.AspNetCore.Mvc.Filters;

namespace PharmaInventory.Api.Middleware;

/// <summary>
/// Filtro global de MVC: por cada argumento de accion que tenga un
/// IValidator&lt;T&gt; registrado (ver Validators/* en Application), lo corre antes
/// de llegar al controller. Evita tener que llamar ValidateAndThrowAsync a
/// mano en cada endpoint. Un ValidationException la traduce
/// ExceptionHandlingMiddleware a 400 con el detalle de cada campo.
/// </summary>
public sealed class ValidationFilter(IServiceProvider serviceProvider) : IAsyncActionFilter
{
    public async Task OnActionExecutionAsync(ActionExecutingContext context, ActionExecutionDelegate next)
    {
        foreach (var argument in context.ActionArguments.Values)
        {
            if (argument is null) continue;

            var validatorType = typeof(IValidator<>).MakeGenericType(argument.GetType());
            if (serviceProvider.GetService(validatorType) is not IValidator validator) continue;

            var validationContext = new ValidationContext<object>(argument);
            var result = await validator.ValidateAsync(validationContext, context.HttpContext.RequestAborted);
            if (!result.IsValid)
                throw new ValidationException(result.Errors);
        }

        await next();
    }
}

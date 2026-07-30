using FluentValidation;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Application.Validators;

public sealed class ClienteRequestValidator : AbstractValidator<ClienteRequest>
{
    public ClienteRequestValidator()
    {
        RuleFor(x => x.NombreCompleto).NotEmpty().MaximumLength(255);
        RuleFor(x => x.Identificacion).NotEmpty().MaximumLength(255);
        RuleFor(x => x.Email).MaximumLength(255).EmailAddress().When(x => !string.IsNullOrEmpty(x.Email));
    }
}

public sealed class LineaRecetaRequestValidator : AbstractValidator<LineaRecetaRequest>
{
    public LineaRecetaRequestValidator()
    {
        RuleFor(x => x.IdProducto).GreaterThan(0);
        RuleFor(x => x.CantidadPrescrita).GreaterThan(0);
    }
}

public sealed class RecetaRequestValidator : AbstractValidator<RecetaRequest>
{
    public RecetaRequestValidator()
    {
        RuleFor(x => x.NumeroReceta).NotEmpty().MaximumLength(255);
        RuleFor(x => x.IdCliente).GreaterThan(0);
        RuleFor(x => x.FechaEmision).NotEmpty();
        RuleFor(x => x.FechaVencimiento)
            .GreaterThanOrEqualTo(x => x.FechaEmision)
            .When(x => x.FechaVencimiento.HasValue)
            .WithMessage("La fecha de vencimiento no puede ser anterior a la de emision.");
        RuleFor(x => x.Detalle).NotEmpty().WithMessage("La receta debe incluir al menos un producto prescrito.");
        RuleForEach(x => x.Detalle).SetValidator(new LineaRecetaRequestValidator());
    }
}

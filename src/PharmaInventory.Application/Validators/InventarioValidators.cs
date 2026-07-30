using FluentValidation;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Application.Validators;

public sealed class AjusteManualRequestValidator : AbstractValidator<AjusteManualRequest>
{
    public AjusteManualRequestValidator()
    {
        RuleFor(x => x.IdProducto).GreaterThan(0);
        RuleFor(x => x.Cantidad).NotEqual(0).WithMessage("La cantidad del ajuste no puede ser cero.");
        RuleFor(x => x.Motivo).NotEmpty().WithMessage("El motivo del ajuste es obligatorio (mermas/conteos deben quedar auditables).");
    }
}

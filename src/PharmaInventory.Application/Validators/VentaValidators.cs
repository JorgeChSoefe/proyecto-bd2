using FluentValidation;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Application.Validators;

public sealed class LineaVentaRequestValidator : AbstractValidator<LineaVentaRequest>
{
    public LineaVentaRequestValidator()
    {
        RuleFor(x => x.IdProducto).GreaterThan(0);
        RuleFor(x => x.Cantidad).GreaterThan(0);
        RuleFor(x => x.PrecioUnitario).GreaterThanOrEqualTo(0);
    }
}

public sealed class VentaRequestValidator : AbstractValidator<VentaRequest>
{
    public VentaRequestValidator()
    {
        RuleFor(x => x.IdEmpleado).GreaterThan(0);
        RuleFor(x => x.Detalle).NotEmpty().WithMessage("La venta debe incluir al menos un producto.");
        RuleForEach(x => x.Detalle).SetValidator(new LineaVentaRequestValidator());
    }
}

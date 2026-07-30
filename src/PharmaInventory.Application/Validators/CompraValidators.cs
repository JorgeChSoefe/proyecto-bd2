using FluentValidation;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Application.Validators;

public sealed class LineaCompraRequestValidator : AbstractValidator<LineaCompraRequest>
{
    public LineaCompraRequestValidator()
    {
        RuleFor(x => x.IdProducto).GreaterThan(0);
        RuleFor(x => x.Cantidad).GreaterThan(0);
        RuleFor(x => x.PrecioUnitario).GreaterThanOrEqualTo(0);
        RuleFor(x => x.NumeroLote).NotEmpty().MaximumLength(255);
        RuleFor(x => x.FechaVencimiento).GreaterThan(x => x.FechaFabricacion ?? DateTime.MinValue);
    }
}

public sealed class CompraRequestValidator : AbstractValidator<CompraRequest>
{
    public CompraRequestValidator()
    {
        RuleFor(x => x.IdProveedor).GreaterThan(0);
        RuleFor(x => x.IdEmpleado).GreaterThan(0);
        RuleFor(x => x.Detalle).NotEmpty().WithMessage("La compra debe incluir al menos un producto.");
        RuleForEach(x => x.Detalle).SetValidator(new LineaCompraRequestValidator());
    }
}

public sealed class LineaRecepcionRequestValidator : AbstractValidator<LineaRecepcionRequest>
{
    public LineaRecepcionRequestValidator()
    {
        RuleFor(x => x.IdDetalle).GreaterThan(0);
        RuleFor(x => x.IdProducto).GreaterThan(0);
        RuleFor(x => x.Cantidad).GreaterThan(0);
        RuleFor(x => x.PrecioUnitario).GreaterThanOrEqualTo(0);
        RuleFor(x => x.NumeroLote).NotEmpty().MaximumLength(255);
        RuleFor(x => x.FechaVencimiento).GreaterThan(x => x.FechaFabricacion ?? DateTime.MinValue);
    }
}

public sealed class CompraRecibirRequestValidator : AbstractValidator<CompraRecibirRequest>
{
    public CompraRecibirRequestValidator()
    {
        RuleFor(x => x.Detalle).NotEmpty();
        RuleForEach(x => x.Detalle).SetValidator(new LineaRecepcionRequestValidator());
    }
}

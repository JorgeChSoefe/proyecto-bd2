using FluentValidation;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Application.Validators;

public sealed class ProductoRequestValidator : AbstractValidator<ProductoRequest>
{
    public ProductoRequestValidator()
    {
        RuleFor(x => x.Nombre).NotEmpty().MaximumLength(255);
        RuleFor(x => x.CodigoSku).MaximumLength(255);
        RuleFor(x => x.CodigoBarras).MaximumLength(255);
        RuleFor(x => x.PrecioCosto).GreaterThanOrEqualTo(0);
        RuleFor(x => x.PrecioVenta).GreaterThanOrEqualTo(0);
        RuleFor(x => x.StockMinimo).GreaterThanOrEqualTo(0);
    }
}

public sealed class ProductoUpdateRequestValidator : AbstractValidator<ProductoUpdateRequest>
{
    public ProductoUpdateRequestValidator()
    {
        RuleFor(x => x.Nombre).NotEmpty().MaximumLength(255);
        RuleFor(x => x.CodigoSku).MaximumLength(255);
        RuleFor(x => x.CodigoBarras).MaximumLength(255);
        RuleFor(x => x.PrecioCosto).GreaterThanOrEqualTo(0);
        RuleFor(x => x.PrecioVenta).GreaterThanOrEqualTo(0);
        RuleFor(x => x.StockMinimo).GreaterThanOrEqualTo(0);
    }
}

public sealed class MedicamentoRequestValidator : AbstractValidator<MedicamentoRequest>
{
    public MedicamentoRequestValidator()
    {
        RuleFor(x => x.IdProducto).GreaterThan(0);
        RuleFor(x => x.ViaAdministracion).IsInEnum();
    }
}

public sealed class MedicamentoUpdateRequestValidator : AbstractValidator<MedicamentoUpdateRequest>
{
    public MedicamentoUpdateRequestValidator()
    {
        RuleFor(x => x.ViaAdministracion).IsInEnum();
    }
}

public sealed class MedicamentoPrincipioRequestValidator : AbstractValidator<MedicamentoPrincipioRequest>
{
    public MedicamentoPrincipioRequestValidator()
    {
        RuleFor(x => x.IdMedicamento).GreaterThan(0);
        RuleFor(x => x.IdPrincipio).GreaterThan(0);
        RuleFor(x => x.CantidadPorDosis).GreaterThan(0);
        RuleFor(x => x.Unidad).NotEmpty().MaximumLength(255);
    }
}

using FluentValidation;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Application.Validators;

public sealed class CategoriaRequestValidator : AbstractValidator<CategoriaRequest>
{
    public CategoriaRequestValidator()
    {
        RuleFor(x => x.NombreCategoria).NotEmpty().MaximumLength(255);
        RuleFor(x => x.Descripcion).MaximumLength(255);
    }
}

public sealed class ProveedorRequestValidator : AbstractValidator<ProveedorRequest>
{
    public ProveedorRequestValidator()
    {
        RuleFor(x => x.NombreEmpresa).NotEmpty().MaximumLength(255);
        RuleFor(x => x.Email).MaximumLength(255).EmailAddress().When(x => !string.IsNullOrEmpty(x.Email));
    }
}

public sealed class LaboratorioRequestValidator : AbstractValidator<LaboratorioRequest>
{
    public LaboratorioRequestValidator()
    {
        RuleFor(x => x.Nombre).NotEmpty().MaximumLength(255);
        RuleFor(x => x.Email).MaximumLength(255).EmailAddress().When(x => !string.IsNullOrEmpty(x.Email));
        RuleFor(x => x.SitioWeb).MaximumLength(255);
    }
}

public sealed class PrincipioActivoRequestValidator : AbstractValidator<PrincipioActivoRequest>
{
    public PrincipioActivoRequestValidator()
    {
        RuleFor(x => x.NombreInn).NotEmpty().MaximumLength(255);
    }
}

public sealed class PresentacionRequestValidator : AbstractValidator<PresentacionRequest>
{
    public PresentacionRequestValidator()
    {
        RuleFor(x => x.Forma).NotEmpty().MaximumLength(255);
    }
}

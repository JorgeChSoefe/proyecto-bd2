using FluentValidation;
using PharmaInventory.Application.Dtos;

namespace PharmaInventory.Application.Validators;

// Validacion de FORMA unicamente (largo, presencia, rango). La de NEGOCIO
// (usuario duplicado, rol inexistente, etc) la hace el SP via THROW y se
// traduce a excepcion tipada en Infrastructure (SqlErrorMapper).

public sealed class LoginRequestValidator : AbstractValidator<LoginRequest>
{
    public LoginRequestValidator()
    {
        RuleFor(x => x.NombreUsuario).NotEmpty().MaximumLength(255);
        RuleFor(x => x.Password).NotEmpty();
    }
}

public sealed class UsuarioRequestValidator : AbstractValidator<UsuarioRequest>
{
    public UsuarioRequestValidator()
    {
        RuleFor(x => x.NombreUsuario).NotEmpty().MaximumLength(255);
        RuleFor(x => x.Email).MaximumLength(255).EmailAddress().When(x => !string.IsNullOrEmpty(x.Email));
        RuleFor(x => x.PasswordHash).NotEmpty();
        RuleFor(x => x.IdRol).GreaterThan(0);
    }
}

public sealed class UsuarioUpdateRequestValidator : AbstractValidator<UsuarioUpdateRequest>
{
    public UsuarioUpdateRequestValidator()
    {
        RuleFor(x => x.Email).MaximumLength(255).EmailAddress().When(x => !string.IsNullOrEmpty(x.Email));
        RuleFor(x => x.IdRol).GreaterThan(0);
    }
}

public sealed class CambiarPasswordRequestValidator : AbstractValidator<CambiarPasswordRequest>
{
    public CambiarPasswordRequestValidator()
    {
        RuleFor(x => x.PasswordActual).NotEmpty();
        RuleFor(x => x.PasswordNueva).NotEmpty().MinimumLength(8);
    }
}

public sealed class RolRequestValidator : AbstractValidator<RolRequest>
{
    public RolRequestValidator()
    {
        RuleFor(x => x.NombreRol).NotEmpty().MaximumLength(255);
    }
}

public sealed class PermisoRequestValidator : AbstractValidator<PermisoRequest>
{
    public PermisoRequestValidator()
    {
        RuleFor(x => x.Modulo).NotEmpty().MaximumLength(255);
        RuleFor(x => x.Accion).NotEmpty().MaximumLength(255);
    }
}

public sealed class EmpleadoRequestValidator : AbstractValidator<EmpleadoRequest>
{
    public EmpleadoRequestValidator()
    {
        RuleFor(x => x.NombreCompleto).NotEmpty().MaximumLength(255);
        RuleFor(x => x.Email).MaximumLength(255).EmailAddress().When(x => !string.IsNullOrEmpty(x.Email));
    }
}

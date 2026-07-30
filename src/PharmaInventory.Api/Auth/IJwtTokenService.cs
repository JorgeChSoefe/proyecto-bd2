using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Api.Auth;

public interface IJwtTokenService
{
    (string Token, DateTime ExpiraEn) GenerarToken(Usuario usuario, IReadOnlyList<Permiso> permisos);
}

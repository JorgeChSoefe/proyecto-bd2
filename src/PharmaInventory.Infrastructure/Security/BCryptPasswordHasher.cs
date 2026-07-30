using PharmaInventory.Application.Abstractions;

namespace PharmaInventory.Infrastructure.Security;

public sealed class BCryptPasswordHasher : IPasswordHasher
{
    private const int WorkFactor = 11;

    // OJO: BCrypt.HashPassword/Verify (no las variantes Enhanced*, que
    // pre-hashean con SHA-384 antes de bcrypt y NO son compatibles con
    // hashes bcrypt "de toda la vida"). El seed (11_Seed_Datos.sql) genero
    // su hash con python3 bcrypt estandar -- debe verificar aqui igual.
    public string Hash(string password) => BCrypt.Net.BCrypt.HashPassword(password, workFactor: WorkFactor);

    public bool Verify(string password, string hash) => BCrypt.Net.BCrypt.Verify(password, hash);
}

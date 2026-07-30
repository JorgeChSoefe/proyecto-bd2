namespace PharmaInventory.Application.Abstractions;

/// <summary>
/// La Api nunca llama a BCrypt directamente ni la BD ve la password en claro
/// -- sp_Usuario_Autenticar solo retorna el hash para que esto lo verifique.
/// </summary>
public interface IPasswordHasher
{
    string Hash(string password);
    bool Verify(string password, string hash);
}

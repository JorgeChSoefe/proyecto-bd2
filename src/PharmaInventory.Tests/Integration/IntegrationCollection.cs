using Xunit;

namespace PharmaInventory.Tests.Integration;

/// <summary>Una sola CustomWebApplicationFactory (y una sola conexion de Kestrel/TestServer) compartida por toda la clase de tests de integracion.</summary>
[CollectionDefinition("Integration")]
public sealed class IntegrationCollection : ICollectionFixture<CustomWebApplicationFactory>;

using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Application.Abstractions;

public interface ICategoriaRepository : ICatalogoRepository<Categoria, CategoriaRequest>;

public interface IProveedorRepository : ICatalogoRepository<Proveedor, ProveedorRequest>;

public interface ILaboratorioRepository : ICatalogoRepository<Laboratorio, LaboratorioRequest>;

public interface IPrincipioActivoRepository : ICatalogoRepository<PrincipioActivo, PrincipioActivoRequest>;

public interface IPresentacionRepository : ICatalogoRepository<Presentacion, PresentacionRequest>;

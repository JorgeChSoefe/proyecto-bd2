using Microsoft.AspNetCore.Mvc;
using PharmaInventory.Application.Abstractions;
using PharmaInventory.Application.Dtos;
using PharmaInventory.Domain.Entities;

namespace PharmaInventory.Api.Controllers;

// Los 7 catalogos que no necesitan nada especial mas alla del CRUD generico
// (ver CatalogoControllerBase). Los modulos de permisos usan guion bajo
// ("principios_activos") para calzar con lo sembrado en 11_Seed_Datos.sql;
// las rutas usan guion medio ("principios-activos") por convencion REST.

[Route("api/roles")]
public sealed class RolesController(IRolRepository repo) : CatalogoControllerBase<Rol, RolRequest>(repo, "roles");

[Route("api/empleados")]
public sealed class EmpleadosController(IEmpleadoRepository repo) : CatalogoControllerBase<Empleado, EmpleadoRequest>(repo, "empleados");

[Route("api/categorias")]
public sealed class CategoriasController(ICategoriaRepository repo) : CatalogoControllerBase<Categoria, CategoriaRequest>(repo, "categorias");

[Route("api/proveedores")]
public sealed class ProveedoresController(IProveedorRepository repo) : CatalogoControllerBase<Proveedor, ProveedorRequest>(repo, "proveedores");

[Route("api/laboratorios")]
public sealed class LaboratoriosController(ILaboratorioRepository repo) : CatalogoControllerBase<Laboratorio, LaboratorioRequest>(repo, "laboratorios");

[Route("api/principios-activos")]
public sealed class PrincipiosActivosController(IPrincipioActivoRepository repo) : CatalogoControllerBase<PrincipioActivo, PrincipioActivoRequest>(repo, "principios_activos");

[Route("api/presentaciones")]
public sealed class PresentacionesController(IPresentacionRepository repo) : CatalogoControllerBase<Presentacion, PresentacionRequest>(repo, "presentaciones");

// Espejo EXACTO de src/PharmaInventory.Application/Validators (y de lo que
// 11_Seed_Datos.sql siembra en `permisos`) -- cambiar esto sin cambiar el
// backend deja huecos de autorizacion invisibles en el sidebar.
// Ojo: 'principios_activos' (guion bajo) es el nombre de MODULO tal cual
// vive en la tabla permisos; la RUTA del catalogo es '/principios-activos'
// (guion medio, convencion REST) -- son cosas distintas a proposito.
export const ACCIONES_POR_MODULO = {
  usuarios: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  roles: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  permisos: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  empleados: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  categorias: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  proveedores: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  laboratorios: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  principios_activos: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  presentaciones: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  productos: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  clientes: ['listar', 'ver', 'crear', 'editar', 'eliminar'],
  medicamentos: ['ver', 'crear', 'editar'],
  inventario: ['consultar', 'ajustar', 'resolver_alerta'],
  recetas: ['listar', 'ver', 'crear'],
  ventas: ['listar', 'ver', 'crear', 'anular'],
  compras: ['listar', 'ver', 'crear', 'recibir', 'anular'],
} as const

export type Modulo = keyof typeof ACCIONES_POR_MODULO

/** Union exacta de cada "modulo:accion" valido -- can('ventas:anular') autocompleta, can('ventas:anulr') no compila. */
export type Permiso = {
  [M in Modulo]: `${M}:${(typeof ACCIONES_POR_MODULO)[M][number]}`
}[Modulo]

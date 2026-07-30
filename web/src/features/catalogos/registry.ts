import type { CrudConfig } from '@/components/crud/crud-config'
import { categoriasConfig } from './configs/categorias.config'
import { empleadosConfig } from './configs/empleados.config'
import { laboratoriosConfig } from './configs/laboratorios.config'
import { permisosConfig } from './configs/permisos.config'
import { presentacionesConfig } from './configs/presentaciones.config'
import { principiosActivosConfig } from './configs/principios-activos.config'
import { proveedoresConfig } from './configs/proveedores.config'
import { rolesConfig } from './configs/roles.config'

// Los 8 catalogos simples que corren enteros sobre el motor generico
// (CrudPage + CrudConfig, ver components/crud/). Usuarios y Clientes viven
// en sus propias features (features/usuarios, features/clientes) por
// convencion de carpetas, aunque tambien usan el mismo motor.
//
// Tipado como CrudConfig<any,any>[] a proposito: cada config individual ya
// esta chequeado contra su TRow/TForm concreto en su propio archivo: TS no
// puede unificar una tupla heterogenea de CrudConfig<A,X>|CrudConfig<B,Y>|...
// contra el generico de <CrudPage config={...}/> en un solo .map(), y forzar
// eso no gana seguridad real (perderla aca es exactamente donde no importa).
export const CATALOGOS: CrudConfig<any, any>[] = [
  categoriasConfig,
  proveedoresConfig,
  laboratoriosConfig,
  principiosActivosConfig,
  presentacionesConfig,
  rolesConfig,
  permisosConfig,
  empleadosConfig,
]

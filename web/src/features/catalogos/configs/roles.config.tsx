import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Rol } from '@/types/api'
import { zTextoOpc, zTextoReq } from '@/lib/validation'
import { RolPermisosAction } from '../components/RolPermisosDialog'

const rolSchema = z.object({
  nombreRol: zTextoReq(255),
  descripcion: zTextoOpc(1000),
})

export type RolForm = z.infer<typeof rolSchema>

export const rolesConfig: CrudConfig<Rol, RolForm> = {
  recurso: 'roles',
  endpoint: '/roles',
  modulo: 'roles',
  titulo: 'Roles',
  tituloSingular: 'Rol',
  getId: (r) => r.idRol,

  columnas: [col.texto<Rol>('nombreRol', 'Nombre'), col.truncado<Rol>('descripcion', 'Descripcion')],

  campos: [
    { name: 'nombreRol', label: 'Nombre', tipo: 'texto', requerido: true, colSpan: 2, autoFocus: true },
    { name: 'descripcion', label: 'Descripcion', tipo: 'textarea', colSpan: 2 },
  ],
  schema: rolSchema,
  valoresPorDefecto: { nombreRol: '', descripcion: undefined },
  aFormulario: (r) => ({ nombreRol: r.nombreRol, descripcion: r.descripcion ?? undefined }),

  // Boton extra por fila -- matriz de permisos del rol (ver Fase 0: GET .../roles/{id}/permisos).
  // JSX (no una llamada directa a la funcion): RolPermisosAction usa hooks
  // (useState/useCan) y necesita una instancia de componente propia por fila.
  acciones: (row) => <RolPermisosAction rol={row} />,

  textoEliminar: (r) => `Se eliminara el rol "${r.nombreRol}". Los usuarios asignados a este rol quedaran sin acceso hasta reasignarlos.`,
}

import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Permiso } from '@/types/api'
import { zTextoOpc, zTextoReq } from '@/lib/validation'

const permisoSchema = z.object({
  modulo: zTextoReq(255),
  accion: zTextoReq(255),
  descripcion: zTextoOpc(1000),
})

export type PermisoForm = z.infer<typeof permisoSchema>

// Catalogo de referencia (lo siembra 11_Seed_Datos.sql) -- se expone CRUD
// completo por consistencia con el resto de catalogos, pero crear un
// permiso "suelto" aca no habilita nada por si solo: el backend solo
// reconoce el par modulo:accion si algun controller realmente lo chequea
// (ver TienePermiso en CatalogoControllerBase / [RequierePermiso]).
export const permisosConfig: CrudConfig<Permiso, PermisoForm> = {
  recurso: 'permisos',
  endpoint: '/permisos',
  modulo: 'permisos',
  titulo: 'Permisos',
  tituloSingular: 'Permiso',
  getId: (r) => r.idPermiso,

  columnas: [
    col.texto<Permiso>('modulo', 'Modulo'),
    col.texto<Permiso>('accion', 'Accion'),
    col.truncado<Permiso>('descripcion', 'Descripcion'),
  ],

  campos: [
    { name: 'modulo', label: 'Modulo', tipo: 'texto', requerido: true, ayuda: 'Debe calzar con el modulo usado en el backend, ej. "ventas".' },
    { name: 'accion', label: 'Accion', tipo: 'texto', requerido: true, ayuda: 'Ej. "listar", "crear", "anular".' },
    { name: 'descripcion', label: 'Descripcion', tipo: 'textarea', colSpan: 2 },
  ],
  schema: permisoSchema,
  valoresPorDefecto: { modulo: '', accion: '', descripcion: undefined },
  aFormulario: (r) => ({ modulo: r.modulo, accion: r.accion, descripcion: r.descripcion ?? undefined }),

  textoEliminar: (r) => `Se eliminara el permiso "${r.modulo}:${r.accion}". Cualquier rol que lo tenga asignado lo perdera.`,
}

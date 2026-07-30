import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { PrincipioActivo } from '@/types/api'
import { zTextoOpc, zTextoReq } from '@/lib/validation'

const principioActivoSchema = z.object({
  nombreInn: zTextoReq(255),
  grupoTerapeutico: zTextoOpc(255),
  descripcion: zTextoOpc(1000),
})

export type PrincipioActivoForm = z.infer<typeof principioActivoSchema>

// Ruta con guion medio ('/principios-activos') por convencion REST, pero el
// modulo de permiso vive con guion bajo ('principios_activos') igual que en
// 11_Seed_Datos.sql -- ver la nota en lib/auth/permissions.ts.
export const principiosActivosConfig: CrudConfig<PrincipioActivo, PrincipioActivoForm> = {
  recurso: 'principios-activos',
  endpoint: '/principios-activos',
  modulo: 'principios_activos',
  titulo: 'Principios activos',
  tituloSingular: 'Principio activo',
  getId: (r) => r.idPrincipio,

  columnas: [
    col.texto<PrincipioActivo>('nombreInn', 'Nombre INN'),
    col.texto<PrincipioActivo>('grupoTerapeutico', 'Grupo terapeutico'),
    col.truncado<PrincipioActivo>('descripcion', 'Descripcion'),
  ],

  campos: [
    { name: 'nombreInn', label: 'Nombre INN', tipo: 'texto', requerido: true, colSpan: 2, autoFocus: true },
    { name: 'grupoTerapeutico', label: 'Grupo terapeutico', tipo: 'texto', colSpan: 2 },
    { name: 'descripcion', label: 'Descripcion', tipo: 'textarea', colSpan: 2 },
  ],
  schema: principioActivoSchema,
  valoresPorDefecto: { nombreInn: '', grupoTerapeutico: undefined, descripcion: undefined },
  aFormulario: (r) => ({
    nombreInn: r.nombreInn,
    grupoTerapeutico: r.grupoTerapeutico ?? undefined,
    descripcion: r.descripcion ?? undefined,
  }),

  textoEliminar: (r) => `Se eliminara el principio activo "${r.nombreInn}". Esta accion no se puede deshacer.`,
}

import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Presentacion } from '@/types/api'
import { zTextoOpc, zTextoReq } from '@/lib/validation'

const presentacionSchema = z.object({
  forma: zTextoReq(255),
  unidadMedida: zTextoOpc(255),
})

export type PresentacionForm = z.infer<typeof presentacionSchema>

export const presentacionesConfig: CrudConfig<Presentacion, PresentacionForm> = {
  recurso: 'presentaciones',
  endpoint: '/presentaciones',
  modulo: 'presentaciones',
  titulo: 'Presentaciones',
  tituloSingular: 'Presentacion',
  getId: (r) => r.idPresentacion,

  columnas: [col.texto<Presentacion>('forma', 'Forma'), col.texto<Presentacion>('unidadMedida', 'Unidad de medida')],

  campos: [
    { name: 'forma', label: 'Forma', tipo: 'texto', requerido: true, colSpan: 2, autoFocus: true, placeholder: 'Tableta, jarabe, ampolla...' },
    { name: 'unidadMedida', label: 'Unidad de medida', tipo: 'texto', colSpan: 2, placeholder: 'mg, ml, unidades...' },
  ],
  schema: presentacionSchema,
  valoresPorDefecto: { forma: '', unidadMedida: undefined },
  aFormulario: (r) => ({ forma: r.forma, unidadMedida: r.unidadMedida ?? undefined }),

  textoEliminar: (r) => `Se eliminara la presentacion "${r.forma}". Esta accion no se puede deshacer.`,
}

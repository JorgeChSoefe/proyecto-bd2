import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Categoria } from '@/types/api'
import { zTextoOpc, zTextoReq } from '@/lib/validation'

const categoriaSchema = z.object({
  nombreCategoria: zTextoReq(255),
  descripcion: zTextoOpc(255),
})

export type CategoriaForm = z.infer<typeof categoriaSchema>

export const categoriasConfig: CrudConfig<Categoria, CategoriaForm> = {
  recurso: 'categorias',
  endpoint: '/categorias',
  modulo: 'categorias',
  titulo: 'Categorias',
  tituloSingular: 'Categoria',
  getId: (r) => r.idCategoria,

  columnas: [col.texto<Categoria>('nombreCategoria', 'Nombre'), col.texto<Categoria>('descripcion', 'Descripcion')],

  campos: [
    { name: 'nombreCategoria', label: 'Nombre', tipo: 'texto', requerido: true, colSpan: 2, autoFocus: true },
    { name: 'descripcion', label: 'Descripcion', tipo: 'textarea', colSpan: 2 },
  ],
  schema: categoriaSchema,
  valoresPorDefecto: { nombreCategoria: '', descripcion: undefined },
  aFormulario: (r) => ({ nombreCategoria: r.nombreCategoria, descripcion: r.descripcion ?? undefined }),

  textoEliminar: (r) => `Se eliminara la categoria "${r.nombreCategoria}". Esta accion no se puede deshacer.`,
}

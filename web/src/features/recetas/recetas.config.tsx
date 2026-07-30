import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Receta } from '@/types/api'
import { NuevaRecetaBoton } from './components/NuevaRecetaBoton'

const schema = z.object({})
type RecetaForm = z.infer<typeof schema>

// Unico listado que existe es "pendientes" (GET /recetas/pendientes) -- no
// acepta busqueda, solo idCliente. Crear/editar/eliminar no aplican aca: el
// alta vive en /recetas/nueva (formulario a medida con LineasEditor).
export const recetasConfig: CrudConfig<Receta, RecetaForm> = {
  recurso: 'recetas-pendientes',
  endpoint: '/recetas/pendientes',
  modulo: 'recetas',
  titulo: 'Recetas pendientes',
  tituloSingular: 'Receta',
  getId: (r) => r.idReceta,
  sinBusqueda: true,

  columnas: [
    col.texto<Receta>('numeroReceta', 'Numero'),
    col.texto<Receta>('nombreCliente', 'Cliente'),
    col.fecha<Receta>('fechaEmision', 'Emision'),
    col.fecha<Receta>('fechaVencimiento', 'Vencimiento'),
  ],
  rutaDetalle: (r) => `/recetas/${r.idReceta}`,

  filtros: [
    {
      tipo: 'lookup',
      param: 'idCliente',
      label: 'Cliente',
      lookup: { recurso: 'clientes', endpoint: '/clientes', campoId: 'idCliente', campoEtiqueta: 'nombreCompleto' },
    },
  ],

  permitirCrear: false,
  permitirEditar: false,
  permitirEliminar: false,
  accionesGlobales: () => <NuevaRecetaBoton />,

  campos: [],
  schema,
  valoresPorDefecto: {},
  aFormulario: () => ({}),
  vacio: { titulo: 'Sin recetas pendientes', descripcion: 'No hay recetas vigentes sin dispensar todavia.' },
}

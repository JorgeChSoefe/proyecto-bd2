import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Compra } from '@/types/api'
import { NuevaCompraBoton } from './components/NuevaCompraBoton'

const schema = z.object({})
type CompraForm = z.infer<typeof schema>

const MAPA_ESTADO: Record<string, { label: string; variant: 'default' | 'secondary' | 'destructive' }> = {
  pendiente: { label: 'Pendiente', variant: 'secondary' },
  recibida: { label: 'Recibida', variant: 'default' },
  anulada: { label: 'Anulada', variant: 'destructive' },
}

// Lectura solamente -- registrar/recibir es el wizard a medida (/compras/nueva -> /compras/:id/recibir).
export const comprasConfig: CrudConfig<Compra, CompraForm> = {
  recurso: 'compras',
  endpoint: '/compras',
  modulo: 'compras',
  titulo: 'Compras',
  tituloSingular: 'Compra',
  getId: (r) => r.idCompra,
  sinBusqueda: true,

  columnas: [
    col.fechaHora<Compra>('fechaCompra', 'Fecha'),
    col.texto<Compra>('nombreProveedor', 'Proveedor'),
    col.texto<Compra>('nombreEmpleado', 'Empleado'),
    col.moneda<Compra>('total', 'Total'),
    col.badge<Compra>('estado', 'Estado', MAPA_ESTADO),
  ],
  rutaDetalle: (r) => `/compras/${r.idCompra}`,

  filtros: [
    {
      tipo: 'select',
      param: 'estado',
      label: 'Estado',
      opciones: [
        { valor: 'pendiente', etiqueta: 'Pendiente' },
        { valor: 'recibida', etiqueta: 'Recibida' },
        { valor: 'anulada', etiqueta: 'Anulada' },
      ],
    },
    { tipo: 'fecha', param: 'fechaDesde', label: 'Desde' },
    { tipo: 'fecha', param: 'fechaHasta', label: 'Hasta' },
  ],

  permitirCrear: false,
  permitirEditar: false,
  permitirEliminar: false,
  accionesGlobales: () => <NuevaCompraBoton />,

  campos: [],
  schema,
  valoresPorDefecto: {},
  aFormulario: () => ({}),
}

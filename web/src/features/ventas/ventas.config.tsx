import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Venta } from '@/types/api'
import { NuevaVentaBoton } from './components/NuevaVentaBoton'

const schema = z.object({})
type VentaForm = z.infer<typeof schema>

const MAPA_ESTADO: Record<string, { label: string; variant: 'default' | 'secondary' | 'destructive' }> = {
  pendiente: { label: 'Pendiente', variant: 'secondary' },
  completada: { label: 'Completada', variant: 'default' },
  anulada: { label: 'Anulada', variant: 'destructive' },
}

// Lectura solamente -- registrar una venta es un flujo a medida (/ventas/nueva,
// LineasEditor + deteccion de receta), no un dialog del motor generico.
export const ventasConfig: CrudConfig<Venta, VentaForm> = {
  recurso: 'ventas',
  endpoint: '/ventas',
  modulo: 'ventas',
  titulo: 'Ventas',
  tituloSingular: 'Venta',
  getId: (r) => r.idVenta,
  sinBusqueda: true,

  columnas: [
    col.fechaHora<Venta>('fechaVenta', 'Fecha'),
    col.texto<Venta>('nombreCliente', 'Cliente'),
    col.texto<Venta>('nombreEmpleado', 'Empleado'),
    col.moneda<Venta>('total', 'Total'),
    col.badge<Venta>('estado', 'Estado', MAPA_ESTADO),
  ],
  rutaDetalle: (r) => `/ventas/${r.idVenta}`,

  filtros: [
    {
      tipo: 'select',
      param: 'estado',
      label: 'Estado',
      opciones: [
        { valor: 'pendiente', etiqueta: 'Pendiente' },
        { valor: 'completada', etiqueta: 'Completada' },
        { valor: 'anulada', etiqueta: 'Anulada' },
      ],
    },
    { tipo: 'fecha', param: 'fechaDesde', label: 'Desde' },
    { tipo: 'fecha', param: 'fechaHasta', label: 'Hasta' },
  ],

  permitirCrear: false,
  permitirEditar: false,
  permitirEliminar: false,
  accionesGlobales: () => <NuevaVentaBoton />,

  campos: [],
  schema,
  valoresPorDefecto: {},
  aFormulario: () => ({}),
}

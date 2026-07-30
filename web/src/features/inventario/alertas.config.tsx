import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { AlertaStock } from '@/types/api'
import { ResolverAccion } from './components/ResolverAccion'

const schema = z.object({})
type AlertaForm = z.infer<typeof schema>

const MAPA_TIPO: Record<string, { label: string; variant: 'default' | 'secondary' | 'destructive' }> = {
  vencimiento_proximo: { label: 'Vencimiento proximo', variant: 'destructive' },
  stock_minimo: { label: 'Stock minimo', variant: 'default' },
  lote_agotado: { label: 'Lote agotado', variant: 'secondary' },
}

export const alertasConfig: CrudConfig<AlertaStock, AlertaForm> = {
  recurso: 'inventario-alertas',
  endpoint: '/inventario/alertas',
  modulo: 'inventario',
  accionListar: 'consultar',
  titulo: 'Alertas',
  tituloSingular: 'Alerta',
  getId: (r) => r.idAlerta,
  sinBusqueda: true, // sp_Alerta_Listar no acepta @busqueda

  columnas: [
    col.badge<AlertaStock>('tipoAlerta', 'Tipo', MAPA_TIPO),
    col.texto<AlertaStock>('nombreProducto', 'Producto'),
    col.texto<AlertaStock>('mensaje', 'Mensaje'),
    col.fechaHora<AlertaStock>('fechaAlerta', 'Fecha'),
    col.bool<AlertaStock>('resuelta', 'Estado', ['Resuelta', 'Activa']),
  ],
  claseFila: (r) => (!r.resuelta ? 'bg-amber-50 dark:bg-amber-950/20' : undefined),

  filtros: [
    {
      tipo: 'select',
      param: 'tipo',
      label: 'Tipo',
      opciones: [
        { valor: 'vencimiento_proximo', etiqueta: 'Vencimiento proximo' },
        { valor: 'stock_minimo', etiqueta: 'Stock minimo' },
        { valor: 'lote_agotado', etiqueta: 'Lote agotado' },
      ],
    },
  ],

  permitirCrear: false,
  permitirEditar: false,
  permitirEliminar: false,
  acciones: (row) => <ResolverAccion alerta={row} />,

  campos: [],
  schema,
  valoresPorDefecto: {},
  aFormulario: () => ({}),
}

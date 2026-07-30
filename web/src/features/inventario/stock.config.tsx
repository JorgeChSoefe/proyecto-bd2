import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { StockActualDto } from '@/types/api'
import { StockAcciones } from './components/StockAcciones'

// Config vacio a proposito -- Stock es de solo lectura (permitirCrear/Editar/
// Eliminar:false), CrudFormDialog/CrudDeleteDialog nunca se renderizan asi
// que estos campos nunca se usan en runtime, solo satisfacen el tipo.
const schema = z.object({})
type StockForm = z.infer<typeof schema>

export const stockConfig: CrudConfig<StockActualDto, StockForm> = {
  recurso: 'inventario-stock',
  endpoint: '/inventario/stock',
  modulo: 'inventario',
  accionListar: 'consultar',
  titulo: 'Stock actual',
  tituloSingular: 'Producto',
  getId: (r) => r.idProducto,

  columnas: [
    col.texto<StockActualDto>('nombre', 'Producto'),
    col.texto<StockActualDto>('codigoSku', 'SKU'),
    col.numero<StockActualDto>('stockActual', 'Stock actual'),
    col.numero<StockActualDto>('stockMinimo', 'Stock minimo'),
    col.moneda<StockActualDto>('precioPromedioPond', 'Costo promedio'),
    col.bool<StockActualDto>('bajoStockMinimo', 'Estado', ['Bajo minimo', 'OK']),
  ],
  claseFila: (r) => (r.bajoStockMinimo ? 'bg-destructive/5' : undefined),

  filtros: [{ tipo: 'switch', param: 'soloBajoMinimo', label: 'Solo bajo minimo' }],

  permitirCrear: false,
  permitirEditar: false,
  permitirEliminar: false,
  acciones: (row) => <StockAcciones row={row} />,

  campos: [],
  schema,
  valoresPorDefecto: {},
  aFormulario: () => ({}),
}

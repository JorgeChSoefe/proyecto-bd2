import type { ReactNode } from 'react'
import { Badge } from '@/components/ui/badge'
import { moneda, numero } from '@/lib/format'
import type { Producto } from '@/types/api'

function Campo({ label, value }: { label: string; value: ReactNode }) {
  return (
    <div>
      <p className="text-muted-foreground text-xs">{label}</p>
      <div className="text-sm">{value}</div>
    </div>
  )
}

/** Solo lectura -- editar nombre/precios/FKs pasa por el CrudFormDialog de la lista de Productos (mismo motor generico). */
export function ProductoGeneralTab({ producto }: { producto: Producto }) {
  return (
    <div className="grid grid-cols-1 gap-4 rounded-md border p-4 sm:grid-cols-3">
      <Campo label="Nombre" value={producto.nombre} />
      <Campo label="Nombre generico" value={producto.nombreGenerico ?? '--'} />
      <Campo label="SKU" value={producto.codigoSku ?? '--'} />
      <Campo label="Codigo de barras" value={producto.codigoBarras ?? '--'} />
      <Campo label="Categoria" value={producto.nombreCategoria ?? '--'} />
      <Campo label="Proveedor" value={producto.proveedor ?? '--'} />
      <Campo label="Laboratorio" value={producto.laboratorio ?? '--'} />
      <Campo label="Presentacion" value={producto.presentacion ?? '--'} />
      <Campo label="Requiere receta" value={<Badge variant={producto.requiereReceta ? 'default' : 'secondary'}>{producto.requiereReceta ? 'Si' : 'No'}</Badge>} />
      <Campo label="Precio costo" value={moneda(producto.precioCosto)} />
      <Campo label="Precio venta" value={moneda(producto.precioVenta)} />
      <Campo label="Costo promedio ponderado" value={moneda(producto.precioPromedioPond)} />
      <Campo label="Stock actual" value={numero(producto.stockActual)} />
      <Campo label="Stock minimo" value={numero(producto.stockMinimo)} />
    </div>
  )
}

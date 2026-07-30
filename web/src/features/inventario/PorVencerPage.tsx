import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { useSearchParams } from 'react-router'
import { DataTable } from '@/components/data-table/DataTable'
import { PageHeader } from '@/components/layout/PageHeader'
import { SinPermiso } from '@/components/feedback/SinPermiso'
import { Button } from '@/components/ui/button'
import { col } from '@/components/crud/columnas'
import { apiFetch } from '@/lib/api/client'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import type { ProductoPorVencerDto } from '@/types/api'
import { AjusteDialog } from './components/AjusteDialog'

const PRESETS = [7, 15, 30, 60, 90]

const columnas = [
  col.texto<ProductoPorVencerDto>('nombre', 'Producto'),
  col.texto<ProductoPorVencerDto>('codigoSku', 'SKU'),
  col.texto<ProductoPorVencerDto>('numeroLote', 'Lote'),
  col.fecha<ProductoPorVencerDto>('fechaVencimiento', 'Vence'),
  col.numero<ProductoPorVencerDto>('diasParaVencer', 'Dias'),
  col.numero<ProductoPorVencerDto>('cantidadActual', 'Cantidad'),
]

export function PorVencerPage() {
  const { can } = useCan()
  const [searchParams, setSearchParams] = useSearchParams()
  const dias = Number(searchParams.get('dias') ?? 30)
  const [ajuste, setAjuste] = useState<{ idProducto: number; idLote: number } | null>(null)

  const { data, isLoading } = useQuery({
    queryKey: qk.inventario.porVencer(dias),
    queryFn: () => apiFetch<ProductoPorVencerDto[]>(`/inventario/por-vencer?dias=${dias}`),
    enabled: can('inventario:consultar'),
  })

  if (!can('inventario:consultar')) return <SinPermiso />

  const columnasConAcciones = can('inventario:ajustar')
    ? [
        ...columnas,
        {
          id: '__acciones__',
          header: '',
          cell: ({ row }: { row: { original: ProductoPorVencerDto } }) => (
            <div className="flex justify-end" onClick={(e) => e.stopPropagation()}>
              <Button
                variant="outline"
                size="sm"
                onClick={() => setAjuste({ idProducto: row.original.idProducto, idLote: row.original.idLote })}
              >
                Ajustar
              </Button>
            </div>
          ),
        },
      ]
    : columnas

  return (
    <div>
      <PageHeader
        titulo="Productos por vencer"
        descripcion="Lotes activos con stock que vencen dentro del rango seleccionado."
        acciones={
          <div className="flex gap-1">
            {PRESETS.map((p) => (
              <Button
                key={p}
                size="sm"
                variant={p === dias ? 'default' : 'outline'}
                onClick={() => setSearchParams((prev) => { const next = new URLSearchParams(prev); next.set('dias', String(p)); return next })}
              >
                {p}d
              </Button>
            ))}
          </div>
        }
      />

      <DataTable
        columnas={columnasConAcciones}
        datos={data ?? []}
        cargando={isLoading}
        getId={(r) => r.idLote}
        vacio={{ titulo: 'Sin productos por vencer', descripcion: `Ningun lote activo vence dentro de los proximos ${dias} dias.` }}
      />

      {ajuste && (
        <AjusteDialog
          open={!!ajuste}
          onOpenChange={(open) => !open && setAjuste(null)}
          idProductoInicial={ajuste.idProducto}
          idLoteInicial={ajuste.idLote}
        />
      )}
    </div>
  )
}

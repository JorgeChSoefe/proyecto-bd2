import { keepPreviousData, useQuery } from '@tanstack/react-query'
import { useNavigate, useParams } from 'react-router'
import { col } from '@/components/crud/columnas'
import { DataTable } from '@/components/data-table/DataTable'
import { Paginacion } from '@/components/data-table/Paginacion'
import { Combobox } from '@/components/forms/Combobox'
import { PageHeader } from '@/components/layout/PageHeader'
import { SinPermiso } from '@/components/feedback/SinPermiso'
import { useTableParams } from '@/hooks/use-table-params'
import { apiFetch, buildQuery } from '@/lib/api/client'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import type { MovimientoKardex } from '@/types/api'
import type { Paginado } from '@/types/pagination'

const PRODUCTO_LOOKUP = { recurso: 'productos', endpoint: '/productos', campoId: 'idProducto', campoEtiqueta: 'nombre', campoSecundario: 'codigoSku' }

const MAPA_TIPO: Record<string, { label: string; variant: 'default' | 'secondary' | 'destructive' }> = {
  entrada: { label: 'Entrada', variant: 'default' },
  salida: { label: 'Salida', variant: 'destructive' },
  ajuste: { label: 'Ajuste', variant: 'secondary' },
}

const columnas = [
  col.fechaHora<MovimientoKardex>('fechaMovimiento', 'Fecha'),
  col.badge<MovimientoKardex>('tipoMovimiento', 'Tipo', MAPA_TIPO),
  col.numero<MovimientoKardex>('cantidadEntrada', 'Entrada'),
  col.numero<MovimientoKardex>('cantidadSalida', 'Salida'),
  col.numero<MovimientoKardex>('saldoStock', 'Saldo'),
  col.moneda<MovimientoKardex>('costoUnitario', 'Costo unitario'),
  col.moneda<MovimientoKardex>('saldoValorado', 'Saldo valorado'),
  col.texto<MovimientoKardex>('observaciones', 'Observaciones'),
  col.texto<MovimientoKardex>('nombreUsuario', 'Usuario'),
]

export function KardexPage() {
  const { can } = useCan()
  const { idProducto: idProductoParam } = useParams()
  const navigate = useNavigate()
  const idProducto = idProductoParam ? Number(idProductoParam) : null
  const tabla = useTableParams({ sinBusqueda: true })

  const { data, isLoading, isPlaceholderData } = useQuery({
    queryKey: idProducto ? qk.inventario.kardex(idProducto, { pagina: tabla.pagina, tamano: tabla.tamano }) : ['inventario', 'kardex', 'sin-producto'],
    queryFn: () =>
      apiFetch<Paginado<MovimientoKardex>>(`/inventario/kardex/${idProducto}${buildQuery({ pagina: tabla.pagina, tamano: tabla.tamano })}`),
    enabled: !!idProducto && can('inventario:consultar'),
    placeholderData: keepPreviousData,
  })

  if (!can('inventario:consultar')) return <SinPermiso />

  return (
    <div>
      <PageHeader titulo="Kardex" descripcion="Historial de movimientos de stock de un producto." />

      <div className="mb-4 max-w-sm">
        <Combobox
          lookup={PRODUCTO_LOOKUP}
          value={idProducto}
          onChange={(v) => navigate(v ? `/inventario/kardex/${v}` : '/inventario/kardex')}
          placeholder="Selecciona un producto..."
        />
      </div>

      {!idProducto ? (
        <p className="text-muted-foreground text-sm">Selecciona un producto para ver su historial de movimientos.</p>
      ) : (
        <>
          <DataTable columnas={columnas} datos={data?.items ?? []} cargando={isLoading} esPlaceholder={isPlaceholderData} getId={(r) => r.idMovimiento} />
          {data && (
            <Paginacion
              pagina={tabla.pagina}
              tamano={tabla.tamano}
              total={data.total}
              onPaginaChange={tabla.setPagina}
              deshabilitada={isPlaceholderData}
            />
          )}
        </>
      )}
    </div>
  )
}

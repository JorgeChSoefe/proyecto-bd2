import { useQuery } from '@tanstack/react-query'
import { Link, Navigate, useParams } from 'react-router'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { PageHeader } from '@/components/layout/PageHeader'
import { SinPermiso } from '@/components/feedback/SinPermiso'
import { Skeleton } from '@/components/ui/skeleton'
import { apiFetch } from '@/lib/api/client'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import { fecha } from '@/lib/format'
import type { RecetaDetalleDto } from '@/types/api'

function Campo({ label, value }: { label: string; value: string | null | undefined }) {
  return (
    <div>
      <p className="text-muted-foreground text-xs">{label}</p>
      <p className="text-sm">{value?.trim() ? value : '--'}</p>
    </div>
  )
}

export function RecetaDetallePage() {
  const { id } = useParams()
  const idReceta = Number(id)
  const { can } = useCan()

  const { data, isLoading } = useQuery({
    queryKey: qk.recetas.detalle(idReceta),
    queryFn: () => apiFetch<RecetaDetalleDto>(`/recetas/${idReceta}`),
    enabled: can('recetas:ver') && Number.isFinite(idReceta),
  })

  if (!Number.isFinite(idReceta)) return <Navigate to="/recetas" replace />
  if (!can('recetas:ver')) return <SinPermiso />

  if (isLoading || !data) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-40 w-full" />
      </div>
    )
  }

  const { receta, lineas } = data
  const vigente = !receta.fechaVencimiento || new Date(receta.fechaVencimiento) >= new Date(new Date().toDateString())
  const puedeVender = !receta.dispensada && vigente && can('ventas:crear')

  return (
    <div>
      <PageHeader
        titulo={`Receta ${receta.numeroReceta}`}
        descripcion={receta.nombreCliente ?? undefined}
        acciones={
          puedeVender && (
            <Button asChild>
              <Link to={`/ventas/nueva?idReceta=${receta.idReceta}&idCliente=${receta.idCliente}`}>Vender con esta receta</Link>
            </Button>
          )
        }
      />

      <div className="mb-6 flex flex-wrap gap-2">
        <Badge variant={receta.dispensada ? 'secondary' : 'default'}>{receta.dispensada ? 'Dispensada' : 'Pendiente'}</Badge>
        <Badge variant={vigente ? 'secondary' : 'destructive'}>{vigente ? 'Vigente' : 'Vencida'}</Badge>
      </div>

      <div className="mb-6 grid grid-cols-1 gap-4 rounded-md border p-4 sm:grid-cols-3">
        <Campo label="Cliente" value={receta.nombreCliente} />
        <Campo label="Medico" value={receta.nombreMedico} />
        <Campo label="Num. colegio medico" value={receta.numColegioMedico} />
        <Campo label="Fecha de emision" value={fecha(receta.fechaEmision)} />
        <Campo label="Fecha de vencimiento" value={receta.fechaVencimiento ? fecha(receta.fechaVencimiento) : 'Sin vencimiento'} />
        <Campo label="Notas" value={receta.notas} />
      </div>

      <p className="mb-2 text-sm font-medium">Detalle</p>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Producto</TableHead>
            <TableHead>Cantidad prescrita</TableHead>
            <TableHead>Dosis</TableHead>
            <TableHead>Duracion</TableHead>
            <TableHead>Estado</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {lineas.map((l) => (
            <TableRow key={l.idDetalle}>
              <TableCell>{l.nombreProducto}</TableCell>
              <TableCell>{l.cantidadPrescrita}</TableCell>
              <TableCell>{l.dosis ?? '--'}</TableCell>
              <TableCell>{l.duracionTratamiento ?? '--'}</TableCell>
              <TableCell>
                <Badge variant={l.dispensada ? 'secondary' : 'default'}>{l.dispensada ? 'Dispensada' : 'Pendiente'}</Badge>
              </TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}

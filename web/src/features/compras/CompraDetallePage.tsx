import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Link, Navigate, useParams } from 'react-router'
import {
  AlertDialog,
  AlertDialogAction,
  AlertDialogCancel,
  AlertDialogContent,
  AlertDialogDescription,
  AlertDialogFooter,
  AlertDialogHeader,
  AlertDialogTitle,
} from '@/components/ui/alert-dialog'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { Badge } from '@/components/ui/badge'
import { Button, buttonVariants } from '@/components/ui/button'
import { PageHeader } from '@/components/layout/PageHeader'
import { SinPermiso } from '@/components/feedback/SinPermiso'
import { Skeleton } from '@/components/ui/skeleton'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { apiFetch, ApiError } from '@/lib/api/client'
import { invalidarTrasCompra } from '@/lib/api/invalidaciones'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import { cn } from '@/lib/utils'
import { fecha, fechaHora, moneda } from '@/lib/format'
import type { CompraDetalleDto, EstadoCompra } from '@/types/api'

const MAPA_ESTADO: Record<EstadoCompra, { label: string; variant: 'default' | 'secondary' | 'destructive' }> = {
  pendiente: { label: 'Pendiente', variant: 'secondary' },
  recibida: { label: 'Recibida', variant: 'default' },
  anulada: { label: 'Anulada', variant: 'destructive' },
}

function Campo({ label, value }: { label: string; value: string | null | undefined }) {
  return (
    <div>
      <p className="text-muted-foreground text-xs">{label}</p>
      <p className="text-sm">{value?.trim() ? value : '--'}</p>
    </div>
  )
}

export function CompraDetallePage() {
  const { id } = useParams()
  const idCompra = Number(id)
  const { can } = useCan()
  const qc = useQueryClient()
  const [anularOpen, setAnularOpen] = useState(false)
  const [errorAnular, setErrorAnular] = useState<string | null>(null)

  const { data, isLoading } = useQuery({
    queryKey: qk.compras.detalle(idCompra),
    queryFn: () => apiFetch<CompraDetalleDto>(`/compras/${idCompra}`),
    enabled: can('compras:ver') && Number.isFinite(idCompra),
  })

  const anular = useMutation({
    mutationFn: () => apiFetch(`/compras/${idCompra}/anular`, { method: 'PATCH' }),
    onSuccess: () => {
      invalidarTrasCompra(qc)
      void qc.invalidateQueries({ queryKey: qk.compras.detalle(idCompra) })
      toast.success('Compra anulada.')
      setAnularOpen(false)
    },
    onError: (err) => {
      setErrorAnular(err instanceof ApiError ? (err.problem?.detail ?? err.message) : 'No se pudo anular la compra.')
    },
  })

  if (!Number.isFinite(idCompra)) return <Navigate to="/compras" replace />
  if (!can('compras:ver')) return <SinPermiso />

  if (isLoading || !data) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-64 w-full" />
      </div>
    )
  }

  const { compra, lineas } = data
  const estadoInfo = MAPA_ESTADO[compra.estado]
  const puedeRecibir = compra.estado === 'pendiente' && can('compras:recibir')
  const puedeAnular = compra.estado === 'pendiente' && can('compras:anular')

  return (
    <div>
      <PageHeader
        titulo={`Compra #${compra.idCompra}`}
        descripcion={fechaHora(compra.fechaCompra)}
        acciones={
          <div className="flex gap-2">
            {puedeAnular && (
              <Button variant="destructive" onClick={() => { setErrorAnular(null); setAnularOpen(true) }}>
                Anular
              </Button>
            )}
            {puedeRecibir && (
              <Button asChild>
                <Link to={`/compras/${idCompra}/recibir`}>Recibir compra</Link>
              </Button>
            )}
          </div>
        }
      />

      <div className="mb-6">
        <Badge variant={estadoInfo.variant}>{estadoInfo.label}</Badge>
      </div>

      <div className="mb-6 grid grid-cols-1 gap-4 rounded-md border p-4 sm:grid-cols-3">
        <Campo label="Proveedor" value={compra.nombreProveedor} />
        <Campo label="Empleado" value={compra.nombreEmpleado} />
        <Campo label="Usuario" value={compra.nombreUsuario} />
        <Campo label="Total" value={moneda(compra.total)} />
      </div>

      <p className="mb-2 text-sm font-medium">Detalle</p>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Producto</TableHead>
            <TableHead>Lote</TableHead>
            <TableHead>Vence</TableHead>
            <TableHead>Cantidad</TableHead>
            <TableHead>Precio unitario</TableHead>
            <TableHead>Subtotal</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {lineas.map((l) => (
            <TableRow key={l.idDetalle}>
              <TableCell>{l.nombreProducto}</TableCell>
              <TableCell>{l.numeroLote ?? (l.numeroLotePropuesto ? `${l.numeroLotePropuesto} (propuesto)` : '--')}</TableCell>
              <TableCell>{l.fechaVencimientoReal ? fecha(l.fechaVencimientoReal) : l.fechaVencimientoPropuesta ? `${fecha(l.fechaVencimientoPropuesta)} (propuesto)` : '--'}</TableCell>
              <TableCell>{l.cantidad}</TableCell>
              <TableCell>{moneda(l.precioUnitario)}</TableCell>
              <TableCell>{moneda(l.subtotal)}</TableCell>
            </TableRow>
          ))}
        </TableBody>
      </Table>

      <AlertDialog open={anularOpen} onOpenChange={(open) => { if (!anular.isPending) setAnularOpen(open) }}>
        <AlertDialogContent>
          <AlertDialogHeader>
            <AlertDialogTitle>Anular compra</AlertDialogTitle>
            <AlertDialogDescription>Solo se puede anular mientras este pendiente (sin recibir). No revierte stock porque nunca se movio.</AlertDialogDescription>
          </AlertDialogHeader>
          <AlertaFormulario mensaje={errorAnular} />
          <AlertDialogFooter>
            <AlertDialogCancel disabled={anular.isPending}>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              className={cn(buttonVariants({ variant: 'destructive' }))}
              disabled={anular.isPending}
              onClick={(e) => {
                e.preventDefault()
                anular.mutate()
              }}
            >
              {anular.isPending ? 'Anulando...' : 'Anular'}
            </AlertDialogAction>
          </AlertDialogFooter>
        </AlertDialogContent>
      </AlertDialog>
    </div>
  )
}

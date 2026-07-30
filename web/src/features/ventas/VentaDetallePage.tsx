import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { Navigate, useParams } from 'react-router'
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
import { invalidarTrasVenta } from '@/lib/api/invalidaciones'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import { cn } from '@/lib/utils'
import { fechaHora, moneda } from '@/lib/format'
import type { EstadoVenta, VentaDetalleDto } from '@/types/api'

const MAPA_ESTADO: Record<EstadoVenta, { label: string; variant: 'default' | 'secondary' | 'destructive' }> = {
  pendiente: { label: 'Pendiente', variant: 'secondary' },
  completada: { label: 'Completada', variant: 'default' },
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

export function VentaDetallePage() {
  const { id } = useParams()
  const idVenta = Number(id)
  const { can } = useCan()
  const qc = useQueryClient()
  const [anularOpen, setAnularOpen] = useState(false)
  const [errorAnular, setErrorAnular] = useState<string | null>(null)

  const { data, isLoading } = useQuery({
    queryKey: qk.ventas.detalle(idVenta),
    queryFn: () => apiFetch<VentaDetalleDto>(`/ventas/${idVenta}`),
    enabled: can('ventas:ver') && Number.isFinite(idVenta),
  })

  const anular = useMutation({
    mutationFn: () => apiFetch(`/ventas/${idVenta}/anular`, { method: 'PATCH' }),
    onSuccess: () => {
      invalidarTrasVenta(qc)
      void qc.invalidateQueries({ queryKey: qk.ventas.detalle(idVenta) })
      toast.success('Venta anulada.')
      setAnularOpen(false)
    },
    onError: (err) => {
      // Si el servidor rechaza (ej. ventana de dias vencida), el dialog se queda abierto mostrando el motivo -- nunca cierra en silencio.
      setErrorAnular(err instanceof ApiError ? (err.problem?.detail ?? err.message) : 'No se pudo anular la venta.')
    },
  })

  if (!Number.isFinite(idVenta)) return <Navigate to="/ventas" replace />
  if (!can('ventas:ver')) return <SinPermiso />

  if (isLoading || !data) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-64 w-full" />
      </div>
    )
  }

  const { venta, lineas } = data
  const estadoInfo = MAPA_ESTADO[venta.estado]
  const puedeAnular = venta.estado === 'completada' && can('ventas:anular')

  return (
    <div>
      <PageHeader
        titulo={`Venta #${venta.idVenta}`}
        descripcion={fechaHora(venta.fechaVenta)}
        acciones={
          puedeAnular && (
            <Button variant="destructive" onClick={() => { setErrorAnular(null); setAnularOpen(true) }}>
              Anular venta
            </Button>
          )
        }
      />

      <div className="mb-6">
        <Badge variant={estadoInfo.variant}>{estadoInfo.label}</Badge>
      </div>

      <div className="mb-6 grid grid-cols-1 gap-4 rounded-md border p-4 sm:grid-cols-3">
        <Campo label="Cliente" value={venta.nombreCliente} />
        <Campo label="Empleado" value={venta.nombreEmpleado} />
        <Campo label="Usuario" value={venta.nombreUsuario} />
        <Campo label="Total" value={moneda(venta.total)} />
      </div>

      <p className="mb-2 text-sm font-medium">Detalle</p>
      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Producto</TableHead>
            <TableHead>Lote</TableHead>
            <TableHead>Cantidad</TableHead>
            <TableHead>Precio unitario</TableHead>
            <TableHead>Subtotal</TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {lineas.map((l) => (
            <TableRow key={l.idDetalle}>
              <TableCell>{l.nombreProducto}</TableCell>
              <TableCell>{l.numeroLote ?? '--'}</TableCell>
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
            <AlertDialogTitle>Anular venta</AlertDialogTitle>
            <AlertDialogDescription>
              Esta accion revierte el stock de cada linea al inventario. Solo se puede anular dentro de la ventana de dias permitida.
            </AlertDialogDescription>
          </AlertDialogHeader>
          <AlertaFormulario mensaje={errorAnular} />
          <AlertDialogFooter>
            <AlertDialogCancel disabled={anular.isPending}>Cancelar</AlertDialogCancel>
            <AlertDialogAction
              className={cn(buttonVariants({ variant: 'destructive' }))}
              disabled={anular.isPending}
              // preventDefault: AlertDialogAction cierra el dialog automaticamente al hacer
              // clic salvo que se cancele -- si el servidor rechaza (ventana de dias vencida),
              // el dialog debe quedarse abierto mostrando el motivo, no cerrar en silencio.
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

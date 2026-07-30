import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect, useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useForm, type Resolver } from 'react-hook-form'
import { toast } from 'sonner'
import { Navigate, useNavigate, useParams } from 'react-router'
import { z } from 'zod'
import { LineasEditor, type ColumnaLinea } from '@/components/forms/LineasEditor'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { PageHeader } from '@/components/layout/PageHeader'
import { SinPermiso } from '@/components/feedback/SinPermiso'
import { Skeleton } from '@/components/ui/skeleton'
import { apiFetch } from '@/lib/api/client'
import { aplicarErroresServidor } from '@/lib/api/problem-details'
import { invalidarTrasCompra } from '@/lib/api/invalidaciones'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import { zEnteroPos, zFechaISO, zFechaISOOpc, zId, zMonto, zTextoReq } from '@/lib/validation'
import type { CompraDetalleDto, DetalleCompra } from '@/types/api'

const lineaRecepcionSchema = z.object({
  idDetalle: zId,
  idProducto: zId,
  cantidad: zEnteroPos,
  precioUnitario: zMonto,
  numeroLote: zTextoReq(255),
  fechaFabricacion: zFechaISOOpc,
  fechaVencimiento: zFechaISO,
})

const recibirSchema = z.object({ detalle: z.array(lineaRecepcionSchema).min(1) })
type RecibirForm = z.infer<typeof recibirSchema>

/** Badge de solo lectura -- idDetalle/producto son fijos para esta linea, nunca cambian durante la recepcion. */
function InfoLineaCelda({ linea }: { linea: DetalleCompra }) {
  return (
    <div>
      <p className="text-sm font-medium">{linea.nombreProducto}</p>
      <Badge variant="outline" className="mt-1">
        Detalle #{linea.idDetalle}
      </Badge>
    </div>
  )
}

function aFormulario(lineas: DetalleCompra[]): RecibirForm {
  return {
    detalle: lineas.map((l) => ({
      idDetalle: l.idDetalle,
      idProducto: l.idProducto,
      cantidad: l.cantidad,
      precioUnitario: l.precioUnitario,
      // Prellenado con lo propuesto al registrar (sp_Compra_Registrar) -- el usuario ajusta si lo realmente recibido difiere.
      numeroLote: l.numeroLote ?? l.numeroLotePropuesto ?? '',
      fechaFabricacion: l.fechaFabricacionPropuesta ? l.fechaFabricacionPropuesta.slice(0, 10) : undefined,
      fechaVencimiento: (l.fechaVencimientoPropuesta ?? '').slice(0, 10),
    })),
  }
}

/** Paso 2 del wizard -- reanudable: se puede volver a /compras/:id/recibir despues de un cierre de navegador, la compra ya quedo 'pendiente'. */
export function CompraRecibirPage() {
  const { id } = useParams()
  const idCompra = Number(id)
  const navigate = useNavigate()
  const qc = useQueryClient()
  const { can } = useCan()
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)

  const { data, isLoading } = useQuery({
    queryKey: qk.compras.detalle(idCompra),
    queryFn: () => apiFetch<CompraDetalleDto>(`/compras/${idCompra}`),
    enabled: can('compras:recibir') && Number.isFinite(idCompra),
  })

  const form = useForm<RecibirForm>({
    resolver: zodResolver(recibirSchema) as unknown as Resolver<RecibirForm>,
    defaultValues: { detalle: [] },
  })

  useEffect(() => {
    if (data) form.reset(aFormulario(data.lineas))
    // Se rellena EXCLUSIVAMENTE desde la respuesta del servidor -- nunca desde el estado del paso 1 (ver bug B4 en 08_Compras.sql).
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [data])

  if (!Number.isFinite(idCompra)) return <Navigate to="/compras" replace />
  if (!can('compras:recibir')) return <SinPermiso />

  if (isLoading || !data) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-64 w-full" />
      </div>
    )
  }

  if (data.compra.estado !== 'pendiente') return <Navigate to={`/compras/${idCompra}`} replace />

  const COLUMNAS_DETALLE: ColumnaLinea[] = [
    { name: 'producto', label: 'Producto', tipo: 'texto', ancho: 'min-w-48', calculada: (index) => <InfoLineaCelda linea={data.lineas[index]} /> },
    { name: 'cantidad', label: 'Cantidad recibida', tipo: 'numero', ancho: 'w-28' },
    { name: 'precioUnitario', label: 'Precio unitario', tipo: 'moneda', ancho: 'w-32' },
    { name: 'numeroLote', label: 'Numero de lote', tipo: 'texto', ancho: 'w-32' },
    { name: 'fechaFabricacion', label: 'Fabricacion', tipo: 'fecha', ancho: 'w-40' },
    { name: 'fechaVencimiento', label: 'Vencimiento', tipo: 'fecha', ancho: 'w-40' },
  ]

  const onSubmit = form.handleSubmit(async (valores) => {
    setErrorGeneral(null)
    try {
      await apiFetch(`/compras/${idCompra}/recibir`, { method: 'PATCH', body: valores })
      invalidarTrasCompra(qc)
      toast.success('Compra recibida -- lotes y kardex actualizados.')
      navigate(`/compras/${idCompra}`)
    } catch (err) {
      setErrorGeneral(aplicarErroresServidor(err, form, ['detalle']))
    }
  })

  return (
    <div>
      <PageHeader titulo={`Recibir compra #${idCompra}`} descripcion="Paso 2 de 2: confirma lo realmente recibido -- crea los lotes y el movimiento de kardex." />
      <form onSubmit={onSubmit} noValidate className="space-y-6">
        <LineasEditor
          control={form.control}
          name="detalle"
          columnas={COLUMNAS_DETALLE}
          valorNuevaLinea={{}}
          permitirAgregar={false}
          permitirEliminar={false}
        />

        <AlertaFormulario mensaje={errorGeneral} />

        <div className="flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={() => navigate(`/compras/${idCompra}`)}>
            Cancelar
          </Button>
          <Button type="submit" disabled={form.formState.isSubmitting}>
            {form.formState.isSubmitting ? 'Recibiendo...' : 'Confirmar recepcion'}
          </Button>
        </div>
      </form>
    </div>
  )
}

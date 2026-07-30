import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect, useState } from 'react'
import { useQueries, useQuery, useQueryClient } from '@tanstack/react-query'
import { Controller, useFieldArray, useForm, useWatch, type Control, type Resolver } from 'react-hook-form'
import { toast } from 'sonner'
import { useNavigate, useSearchParams } from 'react-router'
import { z } from 'zod'
import { Combobox } from '@/components/forms/Combobox'
import { LineasEditor, type ColumnaLinea } from '@/components/forms/LineasEditor'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { PageHeader } from '@/components/layout/PageHeader'
import { Button } from '@/components/ui/button'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { apiFetch, ApiError } from '@/lib/api/client'
import { aplicarErroresServidor } from '@/lib/api/problem-details'
import { invalidarTrasVenta } from '@/lib/api/invalidaciones'
import { qk } from '@/lib/api/query-keys'
import { moneda } from '@/lib/format'
import { zEnteroPos, zId, zIdOpc, zMonto } from '@/lib/validation'
import type { ProductoDetalleDto, RecetaDetalleDto } from '@/types/api'

const lineaVentaSchema = z.object({
  idProducto: zId,
  cantidad: zEnteroPos,
  precioUnitario: zMonto,
})

const ventaSchema = z
  .object({
    idEmpleado: zId,
    idCliente: zIdOpc,
    idReceta: zIdOpc,
    detalle: z.array(lineaVentaSchema).min(1, 'Agrega al menos un producto'),
  })
  .superRefine((val, ctx) => {
    const vistos = new Set<number>()
    val.detalle.forEach((l, i) => {
      if (vistos.has(l.idProducto)) ctx.addIssue({ code: 'custom', message: 'Producto duplicado', path: ['detalle', i, 'idProducto'] })
      vistos.add(l.idProducto)
    })
  })

type VentaForm = z.infer<typeof ventaSchema>

const EMPLEADO_LOOKUP = { recurso: 'empleados', endpoint: '/empleados', campoId: 'idEmpleado', campoEtiqueta: 'nombreCompleto', campoSecundario: 'cargo' }
const CLIENTE_LOOKUP = { recurso: 'clientes', endpoint: '/clientes', campoId: 'idCliente', campoEtiqueta: 'nombreCompleto', campoSecundario: 'identificacion' }
const PRODUCTO_LOOKUP = { recurso: 'productos', endpoint: '/productos', campoId: 'idProducto', campoEtiqueta: 'nombre', campoSecundario: 'codigoSku' }

const LINEA_VACIA = { idProducto: undefined, cantidad: undefined, precioUnitario: undefined }

function SubtotalCelda({ control, index }: { control: Control<VentaForm>; index: number }) {
  const linea = useWatch({ control, name: `detalle.${index}` })
  const subtotal = (Number(linea?.cantidad) || 0) * (Number(linea?.precioUnitario) || 0)
  return <p className="pt-2 text-sm font-medium tabular-nums">{moneda(subtotal)}</p>
}

export function VentaNuevaPage() {
  const navigate = useNavigate()
  const qc = useQueryClient()
  const [searchParams] = useSearchParams()
  const idRecetaParam = searchParams.get('idReceta')
  const idClienteParam = searchParams.get('idCliente')
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)

  const form = useForm<VentaForm>({
    // Cast necesario: zId/zMonto usan z.coerce, misma limitacion RHF+zod que en CrudFormDialog.
    resolver: zodResolver(ventaSchema) as unknown as Resolver<VentaForm>,
    defaultValues: {
      idEmpleado: undefined as unknown as number,
      idCliente: idClienteParam ? Number(idClienteParam) : undefined,
      idReceta: idRecetaParam ? Number(idRecetaParam) : undefined,
      detalle: [{ ...LINEA_VACIA }] as unknown as VentaForm['detalle'],
    },
  })

  // Instancia separada del MISMO campo array -- comparte `control`, asi que
  // `replace` (usado por "Cargar lineas de la receta") y el useFieldArray
  // interno de LineasEditor quedan sincronizados sobre el mismo estado.
  const { replace } = useFieldArray({ control: form.control, name: 'detalle' })

  const detalle = useWatch({ control: form.control, name: 'detalle' })
  const idProductoUnicos = [...new Set(detalle.map((l) => l?.idProducto).filter((id): id is number => !!id))]

  const resultadosProductos = useQueries({
    queries: idProductoUnicos.map((id) => ({
      queryKey: qk.productos.detalle(id),
      queryFn: () => apiFetch<ProductoDetalleDto>(`/productos/${id}`),
      staleTime: 30_000,
    })),
  })
  const productosInfo = new Map(idProductoUnicos.map((id, i) => [id, resultadosProductos[i].data]))

  const exigeReceta = detalle.some((l) => {
    const info = l?.idProducto ? productosInfo.get(l.idProducto) : undefined
    return info?.producto.requiereReceta || info?.medicamento?.controlado
  })

  const lineasStockInsuficiente = detalle
    .map((l, i) => ({ linea: l, index: i, info: l?.idProducto ? productosInfo.get(l.idProducto) : undefined }))
    .filter((x) => x.info && x.linea?.cantidad && x.linea.cantidad > x.info.producto.stockActual)

  const { data: recetaInfo } = useQuery({
    queryKey: qk.recetas.detalle(Number(idRecetaParam)),
    queryFn: () => apiFetch<RecetaDetalleDto>(`/recetas/${idRecetaParam}`),
    enabled: !!idRecetaParam,
  })

  const cargarLineasDeReceta = async () => {
    if (!recetaInfo) return
    const lineas = await Promise.all(
      recetaInfo.lineas.map(async (l) => {
        const detalleProducto = await qc.fetchQuery({
          queryKey: qk.productos.detalle(l.idProducto),
          queryFn: () => apiFetch<ProductoDetalleDto>(`/productos/${l.idProducto}`),
        })
        return { idProducto: l.idProducto, cantidad: l.cantidadPrescrita, precioUnitario: detalleProducto.producto.precioVenta }
      }),
    )
    replace(lineas as VentaForm['detalle'])
    toast.success('Lineas de la receta cargadas.')
  }

  const total = detalle.reduce((acc, l) => acc + (Number(l?.cantidad) || 0) * (Number(l?.precioUnitario) || 0), 0)

  const COLUMNAS_DETALLE: ColumnaLinea[] = [
    { name: 'idProducto', label: 'Producto', tipo: 'lookup', ancho: 'min-w-56', lookup: PRODUCTO_LOOKUP, onSeleccionar: (index, idProducto) => {
        if (!idProducto) return
        void qc.fetchQuery({ queryKey: qk.productos.detalle(idProducto), queryFn: () => apiFetch<ProductoDetalleDto>(`/productos/${idProducto}`) })
          .then((detalleProducto) => form.setValue(`detalle.${index}.precioUnitario`, detalleProducto.producto.precioVenta))
      } },
    { name: 'cantidad', label: 'Cantidad', tipo: 'numero', ancho: 'w-24' },
    { name: 'precioUnitario', label: 'Precio unitario', tipo: 'moneda', ancho: 'w-32' },
    { name: 'subtotal', label: 'Subtotal', tipo: 'texto', ancho: 'w-32', calculada: (index) => <SubtotalCelda control={form.control} index={index} /> },
  ]

  useEffect(() => {
    if (idClienteParam) form.setValue('idCliente', Number(idClienteParam))
    if (idRecetaParam) form.setValue('idReceta', Number(idRecetaParam))
    // Solo al montar -- los deep-links de Recetas ("Vender con esta receta") no deben pisar ediciones posteriores del usuario.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  // Si el usuario cambia/quita el producto que exigia receta, el error manual
  // de idReceta (seteado en onSubmit) queda pegado -- se limpia apenas deja de aplicar.
  useEffect(() => {
    if (!exigeReceta) form.clearErrors('idReceta')
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [exigeReceta])

  const onSubmit = form.handleSubmit(async (valores) => {
    setErrorGeneral(null)
    if (exigeReceta && !valores.idReceta) {
      form.setError('idReceta', { message: 'Uno o mas productos requieren receta o son controlados -- selecciona una receta valida.' })
      return
    }
    try {
      const idVenta = await apiFetch<number>('/ventas', { method: 'POST', body: valores })
      invalidarTrasVenta(qc, valores.idReceta)
      toast.success('Venta registrada.')
      navigate(`/ventas/${idVenta}`)
    } catch (err) {
      // 409 (stock insuficiente) / 422 (receta invalida) -- nunca resetear el formulario, el cajero no debe re-tipear todo.
      setErrorGeneral(
        err instanceof ApiError
          ? (err.problem?.detail ?? aplicarErroresServidor(err, form, ['idEmpleado', 'idCliente', 'idReceta']))
          : 'No se pudo registrar la venta.',
      )
    }
  })

  return (
    <div>
      <PageHeader titulo="Nueva venta" />
      <form onSubmit={onSubmit} noValidate className="space-y-6">
        <FieldGroup className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <Controller
            name="idEmpleado"
            control={form.control}
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel>
                  Empleado <span className="text-destructive">*</span>
                </FieldLabel>
                <Combobox lookup={EMPLEADO_LOOKUP} value={field.value || null} onChange={field.onChange} allowClear={false} />
                {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
              </Field>
            )}
          />
          <Controller
            name="idCliente"
            control={form.control}
            render={({ field }) => (
              <Field>
                <FieldLabel>Cliente</FieldLabel>
                <Combobox lookup={CLIENTE_LOOKUP} value={field.value ?? null} onChange={field.onChange} />
              </Field>
            )}
          />
          <Controller
            name="idReceta"
            control={form.control}
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel>
                  Receta {exigeReceta && <span className="text-destructive">*</span>}
                </FieldLabel>
                {/* Solo llega via deep-link desde "Vender con esta receta" -- no hay un endpoint de busqueda libre de recetas para armar un picker aca. */}
                <p className="text-sm">
                  {recetaInfo ? `${recetaInfo.receta.numeroReceta} (${recetaInfo.receta.nombreCliente ?? 'cliente'})` : field.value ? `Receta #${field.value}` : 'Ninguna'}
                </p>
                {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
              </Field>
            )}
          />
        </FieldGroup>

        {recetaInfo && (
          <div className="rounded-md border border-blue-300 bg-blue-50 p-3 text-sm dark:border-blue-800 dark:bg-blue-950/30">
            Venta vinculada a la receta <strong>{recetaInfo.receta.numeroReceta}</strong>.{' '}
            <Button type="button" variant="link" className="h-auto p-0" onClick={cargarLineasDeReceta}>
              Cargar lineas de la receta
            </Button>
          </div>
        )}

        {exigeReceta && !recetaInfo && (
          <div className="rounded-md border border-amber-300 bg-amber-50 p-3 text-sm dark:border-amber-800 dark:bg-amber-950/30">
            Uno o mas productos requieren receta o son controlados. Esta venta necesita una receta vigente.
          </div>
        )}

        {lineasStockInsuficiente.length > 0 && (
          <div className="rounded-md border border-amber-300 bg-amber-50 p-3 text-sm dark:border-amber-800 dark:bg-amber-950/30">
            Aviso: {lineasStockInsuficiente.length} linea(s) piden mas cantidad que el stock actual visible. El servidor decide con FEFO al confirmar.
          </div>
        )}

        <div>
          <p className="mb-2 text-sm font-medium">Detalle</p>
          <LineasEditor
            control={form.control}
            name="detalle"
            columnas={COLUMNAS_DETALLE}
            valorNuevaLinea={LINEA_VACIA}
            etiquetaAgregar="Agregar producto"
          />
          {form.formState.errors.detalle?.message && <p className="text-destructive mt-1 text-sm">{form.formState.errors.detalle.message}</p>}
        </div>

        <div className="flex justify-end">
          <p className="text-lg font-semibold">Total: {moneda(total)}</p>
        </div>

        <AlertaFormulario mensaje={errorGeneral} />

        <div className="flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={() => navigate('/ventas')}>
            Cancelar
          </Button>
          <Button type="submit" disabled={form.formState.isSubmitting}>
            {form.formState.isSubmitting ? 'Registrando...' : 'Registrar venta'}
          </Button>
        </div>
      </form>
    </div>
  )
}

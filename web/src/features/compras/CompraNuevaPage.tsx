import { zodResolver } from '@hookform/resolvers/zod'
import { useState } from 'react'
import { Controller, useForm, type Resolver } from 'react-hook-form'
import { toast } from 'sonner'
import { useNavigate } from 'react-router'
import { z } from 'zod'
import { Combobox } from '@/components/forms/Combobox'
import { LineasEditor, type ColumnaLinea } from '@/components/forms/LineasEditor'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { PageHeader } from '@/components/layout/PageHeader'
import { Button } from '@/components/ui/button'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { apiFetch } from '@/lib/api/client'
import { aplicarErroresServidor } from '@/lib/api/problem-details'
import { zEnteroPos, zFechaISO, zFechaISOOpc, zId, zMonto, zTextoReq } from '@/lib/validation'

const lineaCompraSchema = z.object({
  idProducto: zId,
  cantidad: zEnteroPos,
  precioUnitario: zMonto,
  numeroLote: zTextoReq(255),
  fechaFabricacion: zFechaISOOpc,
  fechaVencimiento: zFechaISO,
})

const compraSchema = z
  .object({
    idProveedor: zId,
    idEmpleado: zId,
    detalle: z.array(lineaCompraSchema).min(1, 'Agrega al menos un producto'),
  })
  .superRefine((val, ctx) => {
    const vistos = new Set<number>()
    val.detalle.forEach((l, i) => {
      if (vistos.has(l.idProducto)) ctx.addIssue({ code: 'custom', message: 'Producto duplicado', path: ['detalle', i, 'idProducto'] })
      vistos.add(l.idProducto)
    })
  })

type CompraForm = z.infer<typeof compraSchema>

const PROVEEDOR_LOOKUP = { recurso: 'proveedores', endpoint: '/proveedores', campoId: 'idProveedor', campoEtiqueta: 'nombreEmpresa' }
const EMPLEADO_LOOKUP = { recurso: 'empleados', endpoint: '/empleados', campoId: 'idEmpleado', campoEtiqueta: 'nombreCompleto', campoSecundario: 'cargo' }
const PRODUCTO_LOOKUP = { recurso: 'productos', endpoint: '/productos', campoId: 'idProducto', campoEtiqueta: 'nombre', campoSecundario: 'codigoSku' }

const LINEA_VACIA = {
  idProducto: undefined,
  cantidad: undefined,
  precioUnitario: undefined,
  numeroLote: '',
  fechaFabricacion: undefined,
  fechaVencimiento: undefined,
}

const COLUMNAS_DETALLE: ColumnaLinea[] = [
  { name: 'idProducto', label: 'Producto', tipo: 'lookup', ancho: 'min-w-56', lookup: PRODUCTO_LOOKUP },
  { name: 'cantidad', label: 'Cantidad', tipo: 'numero', ancho: 'w-24' },
  { name: 'precioUnitario', label: 'Precio unitario', tipo: 'moneda', ancho: 'w-32' },
  { name: 'numeroLote', label: 'Numero de lote', tipo: 'texto', ancho: 'w-32' },
  { name: 'fechaFabricacion', label: 'Fabricacion', tipo: 'fecha', ancho: 'w-40' },
  { name: 'fechaVencimiento', label: 'Vencimiento', tipo: 'fecha', ancho: 'w-40' },
]

/** Paso 1 del wizard de compras (sp_Compra_Registrar) -- deja la compra en 'pendiente', sin lotes ni kardex todavia. */
export function CompraNuevaPage() {
  const navigate = useNavigate()
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)

  const form = useForm<CompraForm>({
    resolver: zodResolver(compraSchema) as unknown as Resolver<CompraForm>,
    defaultValues: {
      idProveedor: undefined as unknown as number,
      idEmpleado: undefined as unknown as number,
      detalle: [{ ...LINEA_VACIA }] as unknown as CompraForm['detalle'],
    },
  })

  const onSubmit = form.handleSubmit(async (valores) => {
    setErrorGeneral(null)
    try {
      const idCompra = await apiFetch<number>('/compras', { method: 'POST', body: valores })
      toast.success('Compra registrada -- ahora recibi las lineas.')
      navigate(`/compras/${idCompra}/recibir`)
    } catch (err) {
      setErrorGeneral(aplicarErroresServidor(err, form, ['idProveedor', 'idEmpleado']))
    }
  })

  return (
    <div>
      <PageHeader titulo="Nueva compra" descripcion="Paso 1 de 2: registrar el pedido. Los lotes se crean al recibir." />
      <form onSubmit={onSubmit} noValidate className="space-y-6">
        <FieldGroup className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Controller
            name="idProveedor"
            control={form.control}
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel>
                  Proveedor <span className="text-destructive">*</span>
                </FieldLabel>
                <Combobox lookup={PROVEEDOR_LOOKUP} value={field.value || null} onChange={field.onChange} allowClear={false} />
                {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
              </Field>
            )}
          />
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
        </FieldGroup>

        <div>
          <p className="mb-2 text-sm font-medium">Detalle</p>
          <LineasEditor control={form.control} name="detalle" columnas={COLUMNAS_DETALLE} valorNuevaLinea={LINEA_VACIA} etiquetaAgregar="Agregar producto" />
          {form.formState.errors.detalle?.message && <p className="text-destructive mt-1 text-sm">{form.formState.errors.detalle.message}</p>}
        </div>

        <AlertaFormulario mensaje={errorGeneral} />

        <div className="flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={() => navigate('/compras')}>
            Cancelar
          </Button>
          <Button type="submit" disabled={form.formState.isSubmitting}>
            {form.formState.isSubmitting ? 'Registrando...' : 'Registrar compra'}
          </Button>
        </div>
      </form>
    </div>
  )
}

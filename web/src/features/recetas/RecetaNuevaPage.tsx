import { zodResolver } from '@hookform/resolvers/zod'
import { useState } from 'react'
import { Controller, useForm, type Resolver } from 'react-hook-form'
import { toast } from 'sonner'
import { useNavigate } from 'react-router'
import { z } from 'zod'
import { LineasEditor, type ColumnaLinea } from '@/components/forms/LineasEditor'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { PageHeader } from '@/components/layout/PageHeader'
import { Button } from '@/components/ui/button'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Combobox } from '@/components/forms/Combobox'
import { apiFetch } from '@/lib/api/client'
import { aplicarErroresServidor } from '@/lib/api/problem-details'
import { aFechaISO } from '@/lib/format'
import { zEnteroPos, zFechaISO, zFechaISOOpc, zId, zTextoOpc, zTextoReq } from '@/lib/validation'

const lineaSchema = z.object({
  idProducto: zId,
  cantidadPrescrita: zEnteroPos,
  dosis: zTextoOpc(255),
  duracionTratamiento: zTextoOpc(255),
})

const recetaSchema = z
  .object({
    numeroReceta: zTextoReq(255),
    idCliente: zId,
    nombreMedico: zTextoOpc(255),
    numColegioMedico: zTextoOpc(255),
    fechaEmision: zFechaISO,
    fechaVencimiento: zFechaISOOpc,
    notas: zTextoOpc(2000),
    detalle: z.array(lineaSchema).min(1, 'Agrega al menos una linea'),
  })
  .superRefine((val, ctx) => {
    const vistos = new Set<number>()
    val.detalle.forEach((l, i) => {
      if (vistos.has(l.idProducto)) ctx.addIssue({ code: 'custom', message: 'Producto duplicado en el detalle', path: ['detalle', i, 'idProducto'] })
      vistos.add(l.idProducto)
    })
  })

type RecetaForm = z.infer<typeof recetaSchema>

const COLUMNAS_DETALLE: ColumnaLinea[] = [
  {
    name: 'idProducto',
    label: 'Producto',
    tipo: 'lookup',
    ancho: 'min-w-56',
    lookup: { recurso: 'productos', endpoint: '/productos', campoId: 'idProducto', campoEtiqueta: 'nombre', campoSecundario: 'codigoSku' },
  },
  { name: 'cantidadPrescrita', label: 'Cantidad', tipo: 'numero', ancho: 'w-24' },
  { name: 'dosis', label: 'Dosis', tipo: 'texto', placeholder: 'Ej. 1 tableta c/8h' },
  { name: 'duracionTratamiento', label: 'Duracion', tipo: 'texto', placeholder: 'Ej. 7 dias' },
]

const CLIENTE_LOOKUP = { recurso: 'clientes', endpoint: '/clientes', campoId: 'idCliente', campoEtiqueta: 'nombreCompleto', campoSecundario: 'identificacion' }

export function RecetaNuevaPage() {
  const navigate = useNavigate()
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)

  const form = useForm<RecetaForm>({
    resolver: zodResolver(recetaSchema) as unknown as Resolver<RecetaForm>,
    defaultValues: {
      numeroReceta: '',
      idCliente: undefined as unknown as number,
      nombreMedico: undefined,
      numColegioMedico: undefined,
      fechaEmision: aFechaISO(new Date()),
      fechaVencimiento: undefined,
      notas: undefined,
      detalle: [{ idProducto: undefined as unknown as number, cantidadPrescrita: undefined as unknown as number, dosis: undefined, duracionTratamiento: undefined }],
    },
  })

  const onSubmit = form.handleSubmit(async (valores) => {
    setErrorGeneral(null)
    try {
      const id = await apiFetch<number>('/recetas', { method: 'POST', body: valores })
      toast.success('Receta registrada.')
      navigate(`/recetas/${id}`)
    } catch (err) {
      setErrorGeneral(aplicarErroresServidor(err, form, ['numeroReceta', 'idCliente', 'nombreMedico', 'numColegioMedico', 'fechaEmision', 'fechaVencimiento', 'notas']))
    }
  })

  return (
    <div>
      <PageHeader titulo="Nueva receta" />
      <form onSubmit={onSubmit} noValidate className="space-y-6">
        <FieldGroup className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <Controller
            name="numeroReceta"
            control={form.control}
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel>
                  Numero de receta <span className="text-destructive">*</span>
                </FieldLabel>
                <Input {...field} autoFocus aria-invalid={fieldState.invalid} />
                {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
              </Field>
            )}
          />
          <Controller
            name="idCliente"
            control={form.control}
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel>
                  Cliente <span className="text-destructive">*</span>
                </FieldLabel>
                <Combobox lookup={CLIENTE_LOOKUP} value={field.value || null} onChange={field.onChange} allowClear={false} />
                {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
              </Field>
            )}
          />
          <Controller
            name="nombreMedico"
            control={form.control}
            render={({ field }) => (
              <Field>
                <FieldLabel>Medico</FieldLabel>
                <Input {...field} value={field.value ?? ''} />
              </Field>
            )}
          />
          <Controller
            name="numColegioMedico"
            control={form.control}
            render={({ field }) => (
              <Field>
                <FieldLabel>Num. colegio medico</FieldLabel>
                <Input {...field} value={field.value ?? ''} />
              </Field>
            )}
          />
          <Controller
            name="fechaEmision"
            control={form.control}
            render={({ field, fieldState }) => (
              <Field data-invalid={fieldState.invalid}>
                <FieldLabel>
                  Fecha de emision <span className="text-destructive">*</span>
                </FieldLabel>
                <Input {...field} type="date" aria-invalid={fieldState.invalid} />
                {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
              </Field>
            )}
          />
          <Controller
            name="fechaVencimiento"
            control={form.control}
            render={({ field }) => (
              <Field>
                <FieldLabel>Fecha de vencimiento</FieldLabel>
                <Input {...field} value={field.value ?? ''} type="date" />
              </Field>
            )}
          />
          <div className="sm:col-span-2">
            <Controller
              name="notas"
              control={form.control}
              render={({ field }) => (
                <Field>
                  <FieldLabel>Notas</FieldLabel>
                  <Textarea {...field} value={field.value ?? ''} />
                </Field>
              )}
            />
          </div>
        </FieldGroup>

        <div>
          <p className="mb-2 text-sm font-medium">Detalle</p>
          <LineasEditor
            control={form.control}
            name="detalle"
            columnas={COLUMNAS_DETALLE}
            valorNuevaLinea={{ idProducto: undefined, cantidadPrescrita: undefined, dosis: undefined, duracionTratamiento: undefined }}
            etiquetaAgregar="Agregar producto"
          />
          {form.formState.errors.detalle?.message && <p className="text-destructive mt-1 text-sm">{form.formState.errors.detalle.message}</p>}
        </div>

        <AlertaFormulario mensaje={errorGeneral} />

        <div className="flex justify-end gap-2">
          <Button type="button" variant="outline" onClick={() => navigate('/recetas')}>
            Cancelar
          </Button>
          <Button type="submit" disabled={form.formState.isSubmitting}>
            {form.formState.isSubmitting ? 'Guardando...' : 'Registrar receta'}
          </Button>
        </div>
      </form>
    </div>
  )
}

import { zodResolver } from '@hookform/resolvers/zod'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { useEffect, useState } from 'react'
import { Controller, useForm, type Resolver } from 'react-hook-form'
import { toast } from 'sonner'
import { z } from 'zod'
import { Combobox } from '@/components/forms/Combobox'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { ToggleGroup, ToggleGroupItem } from '@/components/ui/toggle-group'
import { apiFetch, ApiError } from '@/lib/api/client'
import { aplicarErroresServidor } from '@/lib/api/problem-details'
import { invalidarTrasAjusteInventario } from '@/lib/api/invalidaciones'
import { qk } from '@/lib/api/query-keys'
import { zEnteroPos, zIdOpc, zTextoReq } from '@/lib/validation'
import type { LoteDisponibleDto, ProductoDetalleDto } from '@/types/api'

const MOTIVOS_RAPIDOS = ['Merma', 'Conteo fisico', 'Vencido', 'Devolucion', 'Correccion']

const ajusteSchema = z.object({
  idProducto: z.coerce.number().int().positive('Selecciona un producto'),
  idLote: zIdOpc,
  tipo: z.enum(['entrada', 'salida']),
  magnitud: zEnteroPos,
  motivo: zTextoReq(500),
})

type AjusteForm = z.infer<typeof ajusteSchema>

const PRODUCTO_LOOKUP = { recurso: 'productos', endpoint: '/productos', campoId: 'idProducto', campoEtiqueta: 'nombre', campoSecundario: 'codigoSku' }

interface Props {
  open: boolean
  onOpenChange: (open: boolean) => void
  idProductoInicial?: number
  idLoteInicial?: number
}

/** Ajuste manual de inventario (unico endpoint de escritura directa de stock) -- reusado desde Stock/Por vencer/detalle de producto. */
export function AjusteDialog({ open, onOpenChange, idProductoInicial, idLoteInicial }: Props) {
  const qc = useQueryClient()
  const [paso, setPaso] = useState<'formulario' | 'confirmar'>('formulario')
  const [confirmado, setConfirmado] = useState(false)
  const [enviando, setEnviando] = useState(false)
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)

  const form = useForm<AjusteForm>({
    // Cast necesario: zId/zEnteroPos usan z.coerce, misma limitacion de RHF+zod que en CrudFormDialog.
    resolver: zodResolver(ajusteSchema) as unknown as Resolver<AjusteForm>,
    defaultValues: {
      idProducto: idProductoInicial ?? (undefined as unknown as number),
      idLote: idLoteInicial ?? undefined,
      tipo: 'salida',
      magnitud: undefined as unknown as number,
      motivo: '',
    },
  })

  useEffect(() => {
    if (!open) return
    setPaso('formulario')
    setConfirmado(false)
    setErrorGeneral(null)
    form.reset({
      idProducto: idProductoInicial ?? (undefined as unknown as number),
      idLote: idLoteInicial ?? undefined,
      tipo: 'salida',
      magnitud: undefined as unknown as number,
      motivo: '',
    })
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, idProductoInicial, idLoteInicial])

  const idProducto = form.watch('idProducto')
  const idLote = form.watch('idLote')
  const tipo = form.watch('tipo')
  const magnitud = form.watch('magnitud')
  const motivo = form.watch('motivo')

  // GET /productos/{id} devuelve ProductoDetalleDto (producto+medicamento+principios), no un Producto plano.
  const { data: detalle } = useQuery({
    queryKey: ['producto-nombre', idProducto],
    queryFn: () => apiFetch<ProductoDetalleDto>(`/productos/${idProducto}`),
    enabled: !!idProducto,
  })
  const producto = detalle?.producto

  const { data: lotes } = useQuery({
    queryKey: qk.inventario.lotes(idProducto),
    queryFn: () => apiFetch<LoteDisponibleDto[]>(`/inventario/lotes?idProducto=${idProducto}`),
    enabled: !!idProducto,
  })

  const loteSeleccionado = lotes?.find((l) => l.idLote === idLote)

  const irAConfirmar = form.handleSubmit(() => {
    setErrorGeneral(null)
    setPaso('confirmar')
  })

  const confirmar = async () => {
    const valores = form.getValues()
    setEnviando(true)
    setErrorGeneral(null)
    try {
      await apiFetch('/inventario/ajustes', {
        method: 'POST',
        body: {
          idProducto: valores.idProducto,
          idLote: valores.idLote ?? null,
          cantidad: valores.tipo === 'salida' ? -valores.magnitud : valores.magnitud,
          motivo: valores.motivo,
        },
      })
      invalidarTrasAjusteInventario(qc)
      toast.success('Ajuste de inventario registrado.')
      onOpenChange(false)
    } catch (err) {
      setPaso('formulario')
      setErrorGeneral(err instanceof ApiError ? (err.problem?.detail ?? aplicarErroresServidor(err, form, ['idProducto', 'idLote', 'motivo'])) : 'No se pudo registrar el ajuste.')
    } finally {
      setEnviando(false)
    }
  }

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="sm:max-w-lg">
        <DialogHeader>
          <DialogTitle>Ajuste manual de inventario</DialogTitle>
          <DialogDescription>Mueve stock fuera de una venta o compra -- mermas, conteos fisicos, correcciones.</DialogDescription>
        </DialogHeader>

        {paso === 'formulario' && (
          <form onSubmit={irAConfirmar} noValidate>
            <FieldGroup className="gap-4">
              <Controller
                name="idProducto"
                control={form.control}
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel>Producto</FieldLabel>
                    <Combobox
                      lookup={PRODUCTO_LOOKUP}
                      value={field.value || null}
                      onChange={(v) => {
                        field.onChange(v)
                        form.setValue('idLote', undefined)
                      }}
                      disabled={!!idProductoInicial}
                      allowClear={false}
                    />
                    {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                  </Field>
                )}
              />

              <Controller
                name="idLote"
                control={form.control}
                render={({ field }) => (
                  <Field>
                    <FieldLabel>Lote (opcional)</FieldLabel>
                    <Select
                      value={field.value != null ? String(field.value) : undefined}
                      onValueChange={(v) => field.onChange(Number(v))}
                      disabled={!idProducto || !!idLoteInicial}
                    >
                      <SelectTrigger className="w-full">
                        <SelectValue placeholder={idProducto ? 'Sin lote especifico' : 'Selecciona un producto primero'} />
                      </SelectTrigger>
                      <SelectContent>
                        {lotes?.map((l) => (
                          <SelectItem key={l.idLote} value={String(l.idLote)}>
                            {l.numeroLote} -- vence {l.fechaVencimiento.slice(0, 10)} ({l.cantidadActual} u.)
                          </SelectItem>
                        ))}
                      </SelectContent>
                    </Select>
                  </Field>
                )}
              />

              <Controller
                name="tipo"
                control={form.control}
                render={({ field }) => (
                  <Field>
                    <FieldLabel>Tipo de movimiento</FieldLabel>
                    <ToggleGroup type="single" variant="outline" value={field.value} onValueChange={(v) => v && field.onChange(v)}>
                      <ToggleGroupItem value="entrada" className="flex-1">
                        Entrada
                      </ToggleGroupItem>
                      <ToggleGroupItem value="salida" className="flex-1">
                        Salida
                      </ToggleGroupItem>
                    </ToggleGroup>
                  </Field>
                )}
              />

              <Controller
                name="magnitud"
                control={form.control}
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel>Cantidad</FieldLabel>
                    <Input {...field} value={field.value ?? ''} type="number" min={1} aria-invalid={fieldState.invalid} />
                    {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                  </Field>
                )}
              />

              <Controller
                name="motivo"
                control={form.control}
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel>Motivo</FieldLabel>
                    <div className="mb-1 flex flex-wrap gap-1">
                      {MOTIVOS_RAPIDOS.map((m) => (
                        <Button key={m} type="button" variant="outline" size="sm" onClick={() => field.onChange(m)}>
                          {m}
                        </Button>
                      ))}
                    </div>
                    <Textarea {...field} aria-invalid={fieldState.invalid} />
                    {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                  </Field>
                )}
              />

              <AlertaFormulario mensaje={errorGeneral} />
            </FieldGroup>
            <DialogFooter className="mt-4">
              <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
                Cancelar
              </Button>
              <Button type="submit">Continuar</Button>
            </DialogFooter>
          </form>
        )}

        {paso === 'confirmar' && (
          <div>
            <div className="bg-muted rounded-md p-4 text-sm">
              Vas a registrar una <strong>{tipo === 'salida' ? 'SALIDA' : 'ENTRADA'}</strong> de <strong>{magnitud}</strong> unidad(es) de{' '}
              <strong>{producto?.nombre ?? '...'}</strong>
              {loteSeleccionado && (
                <>
                  {' '}
                  (lote <strong>{loteSeleccionado.numeroLote}</strong>)
                </>
              )}
              . Motivo: <em>{motivo}</em>.
            </div>

            <label className="mt-4 flex items-center gap-2 text-sm">
              <Checkbox checked={confirmado} onCheckedChange={(v) => setConfirmado(v === true)} />
              Confirmo que quiero registrar este movimiento.
            </label>

            <AlertaFormulario mensaje={errorGeneral} />

            <DialogFooter className="mt-4">
              <Button type="button" variant="outline" onClick={() => setPaso('formulario')} disabled={enviando}>
                Atras
              </Button>
              <Button type="button" onClick={confirmar} disabled={!confirmado || enviando}>
                {enviando ? 'Registrando...' : 'Confirmar'}
              </Button>
            </DialogFooter>
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}

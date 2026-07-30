import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect, useState } from 'react'
import { useForm, type FieldValues, type Resolver } from 'react-hook-form'
import { toast } from 'sonner'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { FieldGroup } from '@/components/ui/field'
import { aplicarErroresServidor } from '@/lib/api/problem-details'
import { cn } from '@/lib/utils'
import type { CrudConfig } from './crud-config'
import { RenderCampo } from './RenderCampo'

interface CrudFormDialogProps<TRow, TForm extends FieldValues> {
  config: CrudConfig<TRow, TForm>
  open: boolean
  onOpenChange: (open: boolean) => void
  filaEditar: TRow | null
  onCrear: (body: TForm) => Promise<unknown>
  onActualizar: (args: { id: number; body: TForm }) => Promise<unknown>
  enviando: boolean
}

const ANCHO_CLASE = { sm: undefined, md: 'sm:max-w-lg', lg: 'sm:max-w-2xl' } as const

export function CrudFormDialog<TRow, TForm extends FieldValues>({
  config,
  open,
  onOpenChange,
  filaEditar,
  onCrear,
  onActualizar,
  enviando,
}: CrudFormDialogProps<TRow, TForm>) {
  const esEdicion = filaEditar != null
  const schema = esEdicion ? (config.schemaEditar ?? config.schema) : (config.schemaCrear ?? config.schema)
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)

  // El cast es necesario: zodResolver infiere su tipo desde un ZodType
  // concreto, y un generico `TForm extends FieldValues` (constraint, no tipo
  // exacto) nunca satisface esa inferencia por mas que en runtime sea
  // exactamente el shape correcto -- limitacion conocida de combinar RHF +
  // zod + un wrapper generico de formularios.
  const form = useForm<TForm>({
    resolver: zodResolver(schema as never) as unknown as Resolver<TForm>,
    defaultValues: config.valoresPorDefecto as never,
  })

  useEffect(() => {
    if (!open) return
    form.reset(filaEditar ? config.aFormulario(filaEditar) : config.valoresPorDefecto)
    setErrorGeneral(null)
    // Solo al abrir/cambiar de fila -- form/config son estables entre renders del mismo dialog.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, filaEditar])

  const campos = config.campos.filter((c) => {
    if (esEdicion && c.soloEnCrear) return false
    if (!esEdicion && c.soloEnEditar) return false
    return true
  })
  const camposConocidos = config.campos.map((c) => String(c.name))

  const onSubmit = form.handleSubmit(async (valores) => {
    setErrorGeneral(null)
    try {
      if (esEdicion) {
        await onActualizar({ id: config.getId(filaEditar), body: valores })
        toast.success(`${config.tituloSingular} actualizado.`)
      } else {
        await onCrear(valores)
        toast.success(`${config.tituloSingular} creado.`)
      }
      onOpenChange(false)
    } catch (err) {
      setErrorGeneral(aplicarErroresServidor(err, form, camposConocidos))
    }
  })

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className={cn(ANCHO_CLASE[config.anchoDialogo ?? 'sm'])}>
        <DialogHeader>
          <DialogTitle>{esEdicion ? `Editar ${config.tituloSingular}` : `Nuevo/a ${config.tituloSingular}`}</DialogTitle>
        </DialogHeader>
        <form onSubmit={onSubmit} noValidate>
          <FieldGroup className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {campos.map((campo) => (
              <RenderCampo key={String(campo.name)} campo={campo} control={form.control} />
            ))}
          </FieldGroup>
          <div className="mt-4">
            <AlertaFormulario mensaje={errorGeneral} />
          </div>
          <DialogFooter className="mt-4">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancelar
            </Button>
            <Button type="submit" disabled={enviando || form.formState.isSubmitting}>
              {enviando || form.formState.isSubmitting ? 'Guardando...' : 'Guardar'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

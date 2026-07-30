import { useState } from 'react'
import { toast } from 'sonner'
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
import { buttonVariants } from '@/components/ui/button'
import { ApiError } from '@/lib/api/client'
import { cn } from '@/lib/utils'
import type { CrudConfig } from './crud-config'

interface CrudDeleteDialogProps<TRow, TForm extends Record<string, unknown>> {
  config: CrudConfig<TRow, TForm>
  fila: TRow | null
  onOpenChange: (open: boolean) => void
  onEliminar: (id: number) => Promise<unknown>
}

export function CrudDeleteDialog<TRow, TForm extends Record<string, unknown>>({
  config,
  fila,
  onOpenChange,
  onEliminar,
}: CrudDeleteDialogProps<TRow, TForm>) {
  const [enviando, setEnviando] = useState(false)
  const etiqueta = config.etiquetaEliminar ?? 'Eliminar'

  const confirmar = async () => {
    if (!fila) return
    setEnviando(true)
    try {
      await onEliminar(config.getId(fila))
      // Participio regular -ar -> -ado ("eliminar" -> "eliminado", "desactivar" -> "desactivado").
      toast.success(`${config.tituloSingular} ${etiqueta.toLowerCase().replace(/r$/, '')}do.`)
      onOpenChange(false)
    } catch (err) {
      const mensaje = err instanceof ApiError ? (err.problem?.detail ?? err.message) : 'No se pudo completar la operacion.'
      toast.error(mensaje)
    } finally {
      setEnviando(false)
    }
  }

  return (
    <AlertDialog open={fila != null} onOpenChange={(open) => !open && onOpenChange(false)}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>
            {etiqueta} {config.tituloSingular.toLowerCase()}
          </AlertDialogTitle>
          <AlertDialogDescription>
            {fila && config.textoEliminar ? config.textoEliminar(fila) : `Esta accion no se puede deshacer.`}
          </AlertDialogDescription>
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel disabled={enviando}>Cancelar</AlertDialogCancel>
          <AlertDialogAction className={cn(buttonVariants({ variant: 'destructive' }))} disabled={enviando} onClick={confirmar}>
            {enviando ? 'Procesando...' : etiqueta}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  )
}

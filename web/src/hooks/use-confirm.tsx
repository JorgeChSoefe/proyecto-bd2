import { useCallback, useState } from 'react'
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
import { cn } from '@/lib/utils'

interface ConfirmOptions {
  titulo: string
  descripcion?: string
  textoConfirmar?: string
  textoCancelar?: string
  /** Estiliza el boton de confirmar en rojo -- usar para anular/eliminar/ajustes de stock. */
  destructivo?: boolean
}

interface ConfirmState extends ConfirmOptions {
  resolve: (value: boolean) => void
}

/**
 * Confirmacion imperativa: `const ok = await confirm({titulo: '...'})`.
 * El componente que llama debe renderizar `{dialog}` en su JSX para que el
 * modal exista en el DOM.
 */
export function useConfirm() {
  const [estado, setEstado] = useState<ConfirmState | null>(null)

  const confirm = useCallback((options: ConfirmOptions) => {
    return new Promise<boolean>((resolve) => {
      setEstado({ ...options, resolve })
    })
  }, [])

  const cerrar = (resultado: boolean) => {
    estado?.resolve(resultado)
    setEstado(null)
  }

  const dialog = estado ? (
    <AlertDialog open onOpenChange={(open) => !open && cerrar(false)}>
      <AlertDialogContent>
        <AlertDialogHeader>
          <AlertDialogTitle>{estado.titulo}</AlertDialogTitle>
          {estado.descripcion && <AlertDialogDescription>{estado.descripcion}</AlertDialogDescription>}
        </AlertDialogHeader>
        <AlertDialogFooter>
          <AlertDialogCancel onClick={() => cerrar(false)}>{estado.textoCancelar ?? 'Cancelar'}</AlertDialogCancel>
          <AlertDialogAction
            className={cn(estado.destructivo && buttonVariants({ variant: 'destructive' }))}
            onClick={() => cerrar(true)}
          >
            {estado.textoConfirmar ?? 'Confirmar'}
          </AlertDialogAction>
        </AlertDialogFooter>
      </AlertDialogContent>
    </AlertDialog>
  ) : null

  return { confirm, dialog }
}

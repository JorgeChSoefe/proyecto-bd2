import { AlertCircle } from 'lucide-react'
import { Alert, AlertDescription, AlertTitle } from '@/components/ui/alert'

/** Mensajes "sueltos" que no matchearon ningun campo del form, o el `detail` de un 409/422/404. Nunca se descartan en silencio (ver aplicarErroresServidor). */
export function AlertaFormulario({ mensaje }: { mensaje: string | null }) {
  if (!mensaje) return null
  return (
    <Alert variant="destructive">
      <AlertCircle className="size-4" />
      <AlertTitle>No se pudo completar la operacion</AlertTitle>
      <AlertDescription>{mensaje}</AlertDescription>
    </Alert>
  )
}

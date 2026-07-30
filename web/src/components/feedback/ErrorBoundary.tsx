import { isRouteErrorResponse, useRouteError } from 'react-router'
import { Button } from '@/components/ui/button'

/** errorElement del router -- captura errores de render/loader que ningun try/catch de pantalla atrapo. */
export function ErrorBoundary() {
  const error = useRouteError()

  const mensaje = isRouteErrorResponse(error)
    ? `${error.status} ${error.statusText}`
    : error instanceof Error
      ? error.message
      : 'Error desconocido.'

  return (
    <div className="flex min-h-svh flex-col items-center justify-center gap-4 p-6 text-center">
      <p className="text-lg font-semibold">Algo salio mal</p>
      <p className="text-muted-foreground max-w-md text-sm">{mensaje}</p>
      <Button onClick={() => window.location.assign('/')}>Volver al inicio</Button>
    </div>
  )
}

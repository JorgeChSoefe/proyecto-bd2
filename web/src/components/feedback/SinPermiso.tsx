import { ShieldAlert } from 'lucide-react'

/** Se renderiza INLINE en el area de contenido (sidebar/topbar intactos) -- un 403 nunca redirige. */
export function SinPermiso() {
  return (
    <div className="flex flex-col items-center justify-center gap-2 rounded-lg border border-dashed p-12 text-center">
      <ShieldAlert className="text-muted-foreground size-10" />
      <p className="font-medium">No tenes permiso para ver esta seccion.</p>
      <p className="text-muted-foreground text-sm">Si crees que esto es un error, consulta con un administrador.</p>
    </div>
  )
}

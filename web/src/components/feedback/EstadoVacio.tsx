import type { ReactNode } from 'react'
import type { LucideIcon } from 'lucide-react'
import { Inbox } from 'lucide-react'

interface EstadoVacioProps {
  titulo: string
  descripcion?: string
  icono?: LucideIcon
  accion?: ReactNode
}

export function EstadoVacio({ titulo, descripcion, icono: Icono = Inbox, accion }: EstadoVacioProps) {
  return (
    <div className="flex flex-col items-center justify-center gap-2 rounded-lg border border-dashed p-12 text-center">
      <Icono className="text-muted-foreground size-10" />
      <p className="font-medium">{titulo}</p>
      {descripcion && <p className="text-muted-foreground max-w-sm text-sm">{descripcion}</p>}
      {accion}
    </div>
  )
}

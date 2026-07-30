import { useEffect, useState } from 'react'
import { LogOut, Menu, ShieldCheck } from 'lucide-react'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import {
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuLabel,
  DropdownMenuSeparator,
  DropdownMenuTrigger,
} from '@/components/ui/dropdown-menu'
import { CambiarPasswordDialog } from '@/components/forms/CambiarPasswordDialog'
import { useAuth } from '@/lib/auth/auth-context'

const AVISO_COUNTDOWN_MS = 10 * 60 * 1000

export function Topbar({ onAbrirMenu }: { onAbrirMenu?: () => void }) {
  const { sesion, logout } = useAuth()
  const [restanteMs, setRestanteMs] = useState<number | null>(null)
  const [dialogAbierto, setDialogAbierto] = useState(false)

  useEffect(() => {
    if (!sesion) return
    const expiraEnMs = new Date(sesion.expiraEn).getTime()

    const tick = () => setRestanteMs(Math.max(0, expiraEnMs - Date.now()))
    tick()
    const id = window.setInterval(tick, 1000)
    return () => window.clearInterval(id)
  }, [sesion])

  if (!sesion) return null

  const mostrarCountdown = restanteMs != null && restanteMs <= AVISO_COUNTDOWN_MS
  const minutos = restanteMs != null ? Math.floor(restanteMs / 60_000) : 0
  const segundos = restanteMs != null ? Math.floor((restanteMs % 60_000) / 1000) : 0

  return (
    <header className="bg-background flex h-14 items-center justify-between gap-4 border-b px-4">
      <Button variant="ghost" size="icon" className="md:hidden" onClick={onAbrirMenu}>
        <Menu className="size-5" />
      </Button>

      <div />

      <div className="flex items-center gap-3">
        {mostrarCountdown && (
          <span className="text-muted-foreground text-xs tabular-nums">
            Sesion expira en {minutos}:{String(segundos).padStart(2, '0')}
          </span>
        )}
        <Badge variant="secondary" className="gap-1">
          <ShieldCheck className="size-3.5" />
          {sesion.nombreRol}
        </Badge>

        <DropdownMenu>
          <DropdownMenuTrigger asChild>
            <Button variant="ghost" className="gap-2">
              {sesion.nombreUsuario}
            </Button>
          </DropdownMenuTrigger>
          <DropdownMenuContent align="end">
            <DropdownMenuLabel>{sesion.nombreUsuario}</DropdownMenuLabel>
            <DropdownMenuSeparator />
            <DropdownMenuItem onSelect={() => setDialogAbierto(true)}>Cambiar contrasena</DropdownMenuItem>
            <DropdownMenuSeparator />
            <DropdownMenuItem variant="destructive" onSelect={logout}>
              <LogOut className="size-4" />
              Cerrar sesion
            </DropdownMenuItem>
          </DropdownMenuContent>
        </DropdownMenu>
      </div>

      <CambiarPasswordDialog open={dialogAbierto} onOpenChange={setDialogAbierto} />
    </header>
  )
}

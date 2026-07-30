import { NavLink } from 'react-router'
import { cn } from '@/lib/utils'
import { useCan } from '@/lib/auth/use-can'
import { NAV } from './nav-config'

export function Sidebar() {
  const { canAny } = useCan()

  // Un grupo entero desaparece si ningun item queda tras filtrar por permiso
  // -- un cajero ve un menu corto y honesto, no una pared de links muertos.
  const gruposVisibles = NAV.map((grupo) => ({
    ...grupo,
    items: grupo.items.filter((item) => canAny(Array.isArray(item.perm) ? item.perm : [item.perm])),
  })).filter((grupo) => grupo.items.length > 0)

  return (
    <nav className="flex h-full flex-col gap-6 overflow-y-auto p-4">
      <div className="px-2">
        <span className="text-lg font-semibold">FarmaRed 24/7</span>
      </div>
      {gruposVisibles.map((grupo) => (
        <div key={grupo.titulo} className="flex flex-col gap-1">
          <span className="text-muted-foreground px-2 text-xs font-medium uppercase tracking-wide">{grupo.titulo}</span>
          {grupo.items.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                cn(
                  'flex items-center gap-2 rounded-md px-2 py-1.5 text-sm transition-colors',
                  isActive ? 'bg-accent text-accent-foreground font-medium' : 'text-muted-foreground hover:bg-accent/50 hover:text-foreground',
                )
              }
            >
              <item.icono className="size-4 shrink-0" />
              {item.titulo}
            </NavLink>
          ))}
        </div>
      ))}
    </nav>
  )
}

import { useQuery } from '@tanstack/react-query'
import type { LucideIcon } from 'lucide-react'
import { Link } from 'react-router'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Skeleton } from '@/components/ui/skeleton'
import { useCan } from '@/lib/auth/use-can'
import type { Permiso } from '@/lib/auth/permissions'
import { numero } from '@/lib/format'

interface Props {
  titulo: string
  icono: LucideIcon
  permiso: Permiso
  ruta: string
  consulta: () => Promise<number>
}

/** Una tarjeta = un conteo (nunca un monto sumado -- no hay endpoint de agregados). Se oculta si el usuario no tiene el permiso del modulo. */
export function TarjetaConteo({ titulo, icono: Icono, permiso, ruta, consulta }: Props) {
  const { can } = useCan()
  const { data, isLoading } = useQuery({ queryKey: ['dashboard', titulo], queryFn: consulta, enabled: can(permiso) })

  if (!can(permiso)) return null

  return (
    <Link to={ruta}>
      <Card className="transition-colors hover:bg-muted/50">
        <CardHeader>
          <CardTitle className="flex items-center justify-between text-sm font-medium text-muted-foreground">
            {titulo}
            <Icono className="text-muted-foreground size-4" />
          </CardTitle>
        </CardHeader>
        <CardContent>{isLoading ? <Skeleton className="h-8 w-16" /> : <p className="text-2xl font-semibold tabular-nums">{numero(data)}</p>}</CardContent>
      </Card>
    </Link>
  )
}

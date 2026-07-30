import { Plus } from 'lucide-react'
import { Link } from 'react-router'
import { Button } from '@/components/ui/button'
import { useCan } from '@/lib/auth/use-can'

export function NuevaVentaBoton() {
  const { can } = useCan()
  if (!can('ventas:crear')) return null

  return (
    <Button asChild>
      <Link to="/ventas/nueva">
        <Plus className="size-4" />
        Nueva venta
      </Link>
    </Button>
  )
}

import { Plus } from 'lucide-react'
import { Link } from 'react-router'
import { Button } from '@/components/ui/button'
import { useCan } from '@/lib/auth/use-can'

export function NuevaCompraBoton() {
  const { can } = useCan()
  if (!can('compras:crear')) return null

  return (
    <Button asChild>
      <Link to="/compras/nueva">
        <Plus className="size-4" />
        Nueva compra
      </Link>
    </Button>
  )
}

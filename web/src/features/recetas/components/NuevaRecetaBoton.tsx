import { Plus } from 'lucide-react'
import { Link } from 'react-router'
import { Button } from '@/components/ui/button'
import { useCan } from '@/lib/auth/use-can'

export function NuevaRecetaBoton() {
  const { can } = useCan()
  if (!can('recetas:crear')) return null

  return (
    <Button asChild>
      <Link to="/recetas/nueva">
        <Plus className="size-4" />
        Nueva receta
      </Link>
    </Button>
  )
}

import { ChevronLeft, ChevronRight } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { totalPaginas } from '@/types/pagination'

interface PaginacionProps {
  pagina: number
  tamano: number
  total: number
  onPaginaChange: (pagina: number) => void
  deshabilitada?: boolean
}

/** Usado por CrudTable y por cualquier vista paginada que no pasa por el motor CRUD (inventario, ventas, compras). */
export function Paginacion({ pagina, tamano, total, onPaginaChange, deshabilitada }: PaginacionProps) {
  const paginas = totalPaginas({ total, tamano })

  return (
    <div className="flex items-center justify-between gap-4 py-2">
      <span className="text-muted-foreground text-sm">
        {total} resultado{total === 1 ? '' : 's'} -- pagina {pagina} de {paginas}
      </span>
      <div className="flex gap-2">
        <Button
          variant="outline"
          size="sm"
          disabled={pagina <= 1 || deshabilitada}
          onClick={() => onPaginaChange(pagina - 1)}
        >
          <ChevronLeft className="size-4" />
          Anterior
        </Button>
        <Button
          variant="outline"
          size="sm"
          disabled={pagina >= paginas || deshabilitada}
          onClick={() => onPaginaChange(pagina + 1)}
        >
          Siguiente
          <ChevronRight className="size-4" />
        </Button>
      </div>
    </div>
  )
}

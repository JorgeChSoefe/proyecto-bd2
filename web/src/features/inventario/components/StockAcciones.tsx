import { useState } from 'react'
import { ScrollText, SlidersHorizontal } from 'lucide-react'
import { Link } from 'react-router'
import { Button } from '@/components/ui/button'
import { useCan } from '@/lib/auth/use-can'
import type { StockActualDto } from '@/types/api'
import { AjusteDialog } from './AjusteDialog'

export function StockAcciones({ row }: { row: StockActualDto }) {
  const { can } = useCan()
  const [ajusteOpen, setAjusteOpen] = useState(false)

  return (
    <>
      <Button variant="ghost" size="icon" asChild aria-label={`Kardex de ${row.nombre}`}>
        <Link to={`/inventario/kardex/${row.idProducto}`} onClick={(e) => e.stopPropagation()}>
          <ScrollText className="size-4" />
        </Link>
      </Button>
      {can('inventario:ajustar') && (
        <Button variant="ghost" size="icon" aria-label={`Ajustar ${row.nombre}`} onClick={() => setAjusteOpen(true)}>
          <SlidersHorizontal className="size-4" />
        </Button>
      )}
      {ajusteOpen && <AjusteDialog open={ajusteOpen} onOpenChange={setAjusteOpen} idProductoInicial={row.idProducto} />}
    </>
  )
}

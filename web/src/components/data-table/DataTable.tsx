import { flexRender, getCoreRowModel, useReactTable, type ColumnDef } from '@tanstack/react-table'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { TablaSkeleton } from '@/components/feedback/TablaSkeleton'
import { EstadoVacio } from '@/components/feedback/EstadoVacio'
import { cn } from '@/lib/utils'

interface DataTableProps<TRow> {
  columnas: ColumnDef<TRow>[]
  datos: TRow[]
  cargando: boolean
  esPlaceholder?: boolean
  getId: (row: TRow) => number
  claseFila?: (row: TRow) => string | undefined
  onFilaClick?: (row: TRow) => void
  vacio?: { titulo: string; descripcion?: string }
}

/**
 * Tabla headless (@tanstack/react-table) + primitivas de shadcn -- SOLO
 * renderiza columnas, no maneja paginacion/orden/filtro propios: eso ya lo
 * resuelve el servidor (ver use-table-params + los distintos _Listar). Se
 * usa tanto desde el motor CRUD como desde vistas a medida (inventario,
 * ventas, compras).
 */
export function DataTable<TRow>({ columnas, datos, cargando, esPlaceholder, getId, claseFila, onFilaClick, vacio }: DataTableProps<TRow>) {
  const table = useReactTable({ data: datos, columns: columnas, getCoreRowModel: getCoreRowModel() })

  if (cargando) return <TablaSkeleton columnas={columnas.length} />

  if (datos.length === 0) {
    return <EstadoVacio titulo={vacio?.titulo ?? 'Sin resultados'} descripcion={vacio?.descripcion} />
  }

  return (
    <div className={cn('rounded-md border transition-opacity', esPlaceholder && 'opacity-60')}>
      <Table>
        <TableHeader>
          {table.getHeaderGroups().map((headerGroup) => (
            <TableRow key={headerGroup.id}>
              {headerGroup.headers.map((header) => (
                <TableHead key={header.id}>
                  {header.isPlaceholder ? null : flexRender(header.column.columnDef.header, header.getContext())}
                </TableHead>
              ))}
            </TableRow>
          ))}
        </TableHeader>
        <TableBody>
          {table.getRowModel().rows.map((row) => (
            <TableRow
              key={getId(row.original)}
              onClick={onFilaClick ? () => onFilaClick(row.original) : undefined}
              className={cn(onFilaClick && 'cursor-pointer', claseFila?.(row.original))}
            >
              {row.getVisibleCells().map((cell) => (
                <TableCell key={cell.id}>{flexRender(cell.column.columnDef.cell, cell.getContext())}</TableCell>
              ))}
            </TableRow>
          ))}
        </TableBody>
      </Table>
    </div>
  )
}

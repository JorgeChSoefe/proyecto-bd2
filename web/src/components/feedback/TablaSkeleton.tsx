import { Skeleton } from '@/components/ui/skeleton'

export function TablaSkeleton({ filas = 6, columnas = 5 }: { filas?: number; columnas?: number }) {
  return (
    <div className="space-y-2">
      {Array.from({ length: filas }).map((_, fila) => (
        <div key={fila} className="flex gap-4">
          {Array.from({ length: columnas }).map((_, col) => (
            <Skeleton key={col} className="h-8 flex-1" />
          ))}
        </div>
      ))}
    </div>
  )
}

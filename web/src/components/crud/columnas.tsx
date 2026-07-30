import type { ColumnDef } from '@tanstack/react-table'
import { Badge } from '@/components/ui/badge'
import { fecha, fechaHora, moneda, numero } from '@/lib/format'

type ClaveTexto<T> = { [K in keyof T]: T[K] extends string | null | undefined ? K : never }[keyof T] & string
type ClaveNumero<T> = { [K in keyof T]: T[K] extends number | null | undefined ? K : never }[keyof T] & string
type ClaveBool<T> = { [K in keyof T]: T[K] extends boolean | null | undefined ? K : never }[keyof T] & string

/** Helpers para que un CrudConfig quede en pocas lineas sin repetir JSX de columna. */
export const col = {
  texto: <T,>(key: ClaveTexto<T>, header: string): ColumnDef<T> => ({
    accessorKey: key,
    header,
    cell: ({ getValue }) => (getValue() as string | null) ?? '--',
  }),

  truncado: <T,>(key: ClaveTexto<T>, header: string, max = 60): ColumnDef<T> => ({
    accessorKey: key,
    header,
    cell: ({ getValue }) => {
      const valor = (getValue() as string | null) ?? ''
      const corto = valor.length > max ? `${valor.slice(0, max)}...` : valor
      return <span title={valor}>{corto || '--'}</span>
    },
  }),

  numero: <T,>(key: ClaveNumero<T>, header: string): ColumnDef<T> => ({
    accessorKey: key,
    header,
    cell: ({ getValue }) => <span className="tabular-nums">{numero(getValue() as number | null)}</span>,
  }),

  moneda: <T,>(key: ClaveNumero<T>, header: string): ColumnDef<T> => ({
    accessorKey: key,
    header,
    cell: ({ getValue }) => <span className="tabular-nums">{moneda(getValue() as number | null)}</span>,
  }),

  fecha: <T,>(key: ClaveTexto<T>, header: string): ColumnDef<T> => ({
    accessorKey: key,
    header,
    cell: ({ getValue }) => fecha(getValue() as string | null),
  }),

  fechaHora: <T,>(key: ClaveTexto<T>, header: string): ColumnDef<T> => ({
    accessorKey: key,
    header,
    cell: ({ getValue }) => fechaHora(getValue() as string | null),
  }),

  bool: <T,>(key: ClaveBool<T>, header: string, etiquetas: [string, string] = ['Si', 'No']): ColumnDef<T> => ({
    accessorKey: key,
    header,
    cell: ({ getValue }) => (
      <Badge variant={getValue() ? 'default' : 'secondary'}>{getValue() ? etiquetas[0] : etiquetas[1]}</Badge>
    ),
  }),

  badge: <T,>(
    key: ClaveTexto<T>,
    header: string,
    mapa: Record<string, { label: string; variant?: 'default' | 'secondary' | 'destructive' | 'outline' }>,
  ): ColumnDef<T> => ({
    accessorKey: key,
    header,
    cell: ({ getValue }) => {
      const valor = getValue() as string
      const info = mapa[valor] ?? { label: valor, variant: 'outline' as const }
      return <Badge variant={info.variant ?? 'outline'}>{info.label}</Badge>
    },
  }),

  enlace: <T,>(key: ClaveTexto<T>, header: string): ColumnDef<T> => ({
    accessorKey: key,
    header,
    cell: ({ getValue }) => {
      const valor = getValue() as string | null
      if (!valor) return '--'
      const href = valor.startsWith('http') ? valor : `https://${valor}`
      return (
        <a href={href} target="_blank" rel="noreferrer" className="text-primary hover:underline" onClick={(e) => e.stopPropagation()}>
          {valor}
        </a>
      )
    },
  }),
}

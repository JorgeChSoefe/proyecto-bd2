import { format, parseISO } from 'date-fns'
import { es } from 'date-fns/locale'

export function moneda(valor: number | null | undefined): string {
  if (valor == null) return '--'
  return new Intl.NumberFormat('es-CR', { style: 'currency', currency: 'CRC', maximumFractionDigits: 2 }).format(valor)
}

export function numero(valor: number | null | undefined): string {
  if (valor == null) return '--'
  return new Intl.NumberFormat('es-CR').format(valor)
}

/** yyyy-MM-dd o un ISO completo -> dd/MM/yyyy. Nunca lanza si la fecha viene mal formada. */
export function fecha(valor: string | null | undefined): string {
  if (!valor) return '--'
  try {
    return format(parseISO(valor), 'dd/MM/yyyy', { locale: es })
  } catch {
    return valor
  }
}

export function fechaHora(valor: string | null | undefined): string {
  if (!valor) return '--'
  try {
    return format(parseISO(valor), "dd/MM/yyyy HH:mm", { locale: es })
  } catch {
    return valor
  }
}

/** yyyy-MM-dd para <input type="date"> y para mandar a la Api -- nunca serializar un objeto Date. */
export function aFechaISO(date: Date): string {
  return format(date, 'yyyy-MM-dd')
}

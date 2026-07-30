import { useEffect, useState } from 'react'
import { Combobox } from '@/components/forms/Combobox'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Switch } from '@/components/ui/switch'
import { useDebouncedValue } from '@/hooks/use-debounced-value'
import type { FiltroConfig } from './crud-config'

const VALOR_TODOS = '__todos__'

interface ToolbarFiltrosProps {
  busqueda: string | undefined
  onBusquedaChange: (valor: string) => void
  filtros?: FiltroConfig[]
  obtenerFiltro: (param: string) => string | undefined
  onFiltroChange: (param: string, valor: string | undefined) => void
  sinBusqueda?: boolean
}

/** Busqueda con estado local + debounce (300ms) escribiendo a la URL con replace -- ver hooks/use-table-params.ts. */
export function ToolbarFiltros({ busqueda, onBusquedaChange, filtros, obtenerFiltro, onFiltroChange, sinBusqueda }: ToolbarFiltrosProps) {
  const [texto, setTexto] = useState(busqueda ?? '')
  const textoDebounced = useDebouncedValue(texto, 300)

  useEffect(() => {
    if (textoDebounced !== (busqueda ?? '')) onBusquedaChange(textoDebounced)
    // Solo se dispara cuando cambia el valor debounced -- no incluir onBusquedaChange/busqueda evita un loop.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [textoDebounced])

  useEffect(() => {
    setTexto(busqueda ?? '')
  }, [busqueda])

  return (
    <div className="flex flex-wrap items-center gap-2">
      {!sinBusqueda && (
        <Input placeholder="Buscar..." value={texto} onChange={(e) => setTexto(e.target.value)} className="max-w-xs" />
      )}

      {filtros?.map((filtro) => {
        if (filtro.tipo === 'select') {
          return (
            <Select
              key={filtro.param}
              value={obtenerFiltro(filtro.param) ?? VALOR_TODOS}
              onValueChange={(v) => onFiltroChange(filtro.param, v === VALOR_TODOS ? undefined : v)}
            >
              <SelectTrigger className="w-44">
                <SelectValue placeholder={filtro.label} />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value={VALOR_TODOS}>{filtro.label}: todos</SelectItem>
                {filtro.opciones.map((o) => (
                  <SelectItem key={o.valor} value={String(o.valor)}>
                    {o.etiqueta}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )
        }

        if (filtro.tipo === 'switch') {
          return (
            <label key={filtro.param} className="flex items-center gap-2 text-sm">
              <Switch
                checked={obtenerFiltro(filtro.param) === 'true'}
                onCheckedChange={(checked) => onFiltroChange(filtro.param, checked ? 'true' : undefined)}
              />
              {filtro.label}
            </label>
          )
        }

        if (filtro.tipo === 'fecha') {
          return (
            <Input
              key={filtro.param}
              type="date"
              className="w-40"
              value={obtenerFiltro(filtro.param) ?? ''}
              onChange={(e) => onFiltroChange(filtro.param, e.target.value || undefined)}
              aria-label={filtro.label}
              title={filtro.label}
            />
          )
        }

        if (filtro.tipo === 'lookup') {
          const valorActual = obtenerFiltro(filtro.param)
          return (
            <div key={filtro.param} className="w-48">
              <Combobox
                lookup={filtro.lookup}
                value={valorActual ? Number(valorActual) : null}
                onChange={(v) => onFiltroChange(filtro.param, v != null ? String(v) : undefined)}
                placeholder={filtro.label}
              />
            </div>
          )
        }

        return null
      })}
    </div>
  )
}

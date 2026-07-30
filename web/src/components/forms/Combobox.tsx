import { useQuery } from '@tanstack/react-query'
import { Check, ChevronsUpDown } from 'lucide-react'
import { useState } from 'react'
import { Button } from '@/components/ui/button'
import { Command, CommandEmpty, CommandGroup, CommandInput, CommandItem, CommandList } from '@/components/ui/command'
import { Popover, PopoverContent, PopoverTrigger } from '@/components/ui/popover'
import { useDebouncedValue } from '@/hooks/use-debounced-value'
import { type LookupConfig, useLookup } from '@/hooks/use-lookups'
import { apiFetch } from '@/lib/api/client'
import { qk } from '@/lib/api/query-keys'
import { cn } from '@/lib/utils'

interface ComboboxProps {
  lookup: LookupConfig
  value: number | null | undefined
  onChange: (value: number | null) => void
  placeholder?: string
  disabled?: boolean
  allowClear?: boolean
}

type FilaLookup = Record<string, unknown>

/** Select con busqueda server-side contra cualquier endpoint _Listar (campoId/campoEtiqueta configurables). */
export function Combobox({ lookup, value, onChange, placeholder = 'Selecciona...', disabled, allowClear = true }: ComboboxProps) {
  const [open, setOpen] = useState(false)
  const [busquedaInput, setBusquedaInput] = useState('')
  const busquedaDebounced = useDebouncedValue(busquedaInput, 300)

  const { data, isLoading } = useLookup<FilaLookup>(lookup, busquedaDebounced || undefined)
  const items = data?.items ?? []

  // El valor actual puede no estar en la pagina de busqueda cargada (ej. al
  // editar un registro existente antes de que el usuario busque nada) --
  // se resuelve su etiqueta con un fetch puntual por id.
  const yaCargado = items.some((item) => Number(item[lookup.campoId]) === value)
  const { data: itemActual } = useQuery({
    queryKey: qk.lookups(lookup.recurso, `item:${value}`),
    queryFn: () => apiFetch<FilaLookup>(`${lookup.endpoint}/${value}`),
    enabled: value != null && !yaCargado,
    staleTime: 5 * 60_000,
  })

  const seleccionado = items.find((item) => Number(item[lookup.campoId]) === value) ?? itemActual
  const etiquetaDe = (item: FilaLookup | undefined) => (item ? String(item[lookup.campoEtiqueta]) : undefined)

  return (
    <Popover open={open} onOpenChange={setOpen}>
      <PopoverTrigger asChild>
        <Button
          type="button"
          variant="outline"
          role="combobox"
          aria-expanded={open}
          disabled={disabled}
          className="w-full justify-between font-normal"
        >
          {seleccionado ? etiquetaDe(seleccionado) : <span className="text-muted-foreground">{placeholder}</span>}
          <ChevronsUpDown className="text-muted-foreground size-4 shrink-0 opacity-50" />
        </Button>
      </PopoverTrigger>
      <PopoverContent className="w-(--radix-popover-trigger-width) p-0" align="start">
        <Command shouldFilter={false}>
          <CommandInput placeholder="Buscar..." value={busquedaInput} onValueChange={setBusquedaInput} />
          <CommandList>
            {isLoading && <div className="text-muted-foreground p-2 text-sm">Cargando...</div>}
            <CommandEmpty>Sin resultados.</CommandEmpty>
            <CommandGroup>
              {allowClear && value != null && (
                <CommandItem
                  value="__ninguno__"
                  onSelect={() => {
                    onChange(null)
                    setOpen(false)
                  }}
                >
                  <span className="text-muted-foreground italic">Ninguno</span>
                </CommandItem>
              )}
              {items.map((item) => {
                const id = Number(item[lookup.campoId])
                return (
                  <CommandItem
                    key={id}
                    value={String(id)}
                    onSelect={() => {
                      onChange(id)
                      setOpen(false)
                    }}
                  >
                    <Check className={cn('size-4', value === id ? 'opacity-100' : 'opacity-0')} />
                    <div className="flex flex-col">
                      <span>{etiquetaDe(item)}</span>
                      {lookup.campoSecundario && (
                        <span className="text-muted-foreground text-xs">{String(item[lookup.campoSecundario] ?? '')}</span>
                      )}
                    </div>
                  </CommandItem>
                )
              })}
            </CommandGroup>
          </CommandList>
        </Command>
      </PopoverContent>
    </Popover>
  )
}

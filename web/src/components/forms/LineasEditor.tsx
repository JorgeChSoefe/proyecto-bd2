import { Controller, useFieldArray, type Control, type FieldValues } from 'react-hook-form'
import { Plus, Trash2 } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { FieldError } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import type { LookupConfig } from '@/hooks/use-lookups'
import { cn } from '@/lib/utils'
import { Combobox } from './Combobox'

export interface ColumnaLinea {
  name: string
  label: string
  tipo: 'lookup' | 'numero' | 'moneda' | 'texto' | 'fecha'
  lookup?: LookupConfig
  ancho?: string
  placeholder?: string
  /**
   * Celda de solo lectura calculada a partir de otros campos de la fila (ej.
   * subtotal = cantidad * precio). Recibe el INDICE, no el valor -- los
   * `fields` de useFieldArray son un snapshot al momento de agregar la fila,
   * no se actualizan cuando el usuario tipea; el caller debe leer el valor
   * en vivo con `useWatch({control, name: \`${name}.${index}\`})` adentro de
   * su propio componente de celda.
   */
  calculada?: (index: number) => React.ReactNode
  /** Efecto cruzado entre celdas (ej. autollenar precioUnitario al elegir producto). Solo aplica a tipo:'lookup'. */
  onSeleccionar?: (index: number, valor: number | null) => void
}

interface LineasEditorProps<TForm extends FieldValues> {
  control: Control<TForm>
  /** Nombre del campo array en el formulario padre, ej. 'detalle'. */
  name: string
  columnas: ColumnaLinea[]
  valorNuevaLinea: Record<string, unknown>
  permitirAgregar?: boolean
  permitirEliminar?: boolean
  etiquetaAgregar?: string
  minimoLineas?: number
}

/**
 * Editor de lineas generico sobre useFieldArray -- lo usan Recetas, Ventas y
 * Compras (misma UX: agregar fila, quitar fila, error por celda, Enter en la
 * ultima celda agrega una fila nueva). El tipado de `name`/Controller usa
 * casts deliberados: react-hook-form no puede expresar "un array de objetos
 * dentro de un TForm generico" sin perder la ergonomia de esta API.
 */
export function LineasEditor<TForm extends FieldValues>({
  control,
  name,
  columnas,
  valorNuevaLinea,
  permitirAgregar = true,
  permitirEliminar = true,
  etiquetaAgregar = 'Agregar linea',
  minimoLineas = 1,
}: LineasEditorProps<TForm>) {
  const { fields, append, remove } = useFieldArray({ control: control as never, name: name as never })

  return (
    <div className="space-y-2">
      <div className="overflow-x-auto rounded-md border">
        <Table>
          <TableHeader>
            <TableRow>
              {columnas.map((c) => (
                <TableHead key={c.name} className={c.ancho}>
                  {c.label}
                </TableHead>
              ))}
              {permitirEliminar && <TableHead className="w-10" />}
            </TableRow>
          </TableHeader>
          <TableBody>
            {fields.length === 0 && (
              <TableRow>
                <TableCell colSpan={columnas.length + 1} className="text-muted-foreground text-center text-sm">
                  Sin lineas todavia.
                </TableCell>
              </TableRow>
            )}
            {fields.map((field, index) => (
              <TableRow key={field.id}>
                {columnas.map((c) => (
                  <TableCell key={c.name} className="align-top">
                    {c.calculada ? (
                      c.calculada(index)
                    ) : (
                      <Controller
                        name={`${name}.${index}.${c.name}` as never}
                        control={control}
                        render={({ field: rhfField, fieldState }) =>
                          c.tipo === 'lookup' && c.lookup ? (
                            <div className={c.ancho ?? 'min-w-48'}>
                              <Combobox
                                lookup={c.lookup}
                                value={rhfField.value ?? null}
                                onChange={(v) => {
                                  rhfField.onChange(v)
                                  c.onSeleccionar?.(index, v)
                                }}
                                allowClear={false}
                              />
                              {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                            </div>
                          ) : (
                            <div className={cn(c.ancho ?? 'min-w-24')}>
                              <Input
                                {...rhfField}
                                value={(rhfField.value as string | number) ?? ''}
                                type={c.tipo === 'numero' || c.tipo === 'moneda' ? 'number' : c.tipo === 'fecha' ? 'date' : 'text'}
                                step={c.tipo === 'moneda' ? '0.01' : undefined}
                                placeholder={c.placeholder}
                                aria-invalid={fieldState.invalid}
                                onKeyDown={(e) => {
                                  if (e.key === 'Enter' && index === fields.length - 1 && permitirAgregar) {
                                    e.preventDefault()
                                    append(valorNuevaLinea as never)
                                  }
                                }}
                              />
                              {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                            </div>
                          )
                        }
                      />
                    )}
                  </TableCell>
                ))}
                {permitirEliminar && (
                  <TableCell className="align-top">
                    <Button
                      type="button"
                      variant="ghost"
                      size="icon"
                      onClick={() => remove(index)}
                      disabled={fields.length <= minimoLineas}
                      aria-label="Quitar linea"
                    >
                      <Trash2 className="size-4" />
                    </Button>
                  </TableCell>
                )}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </div>
      {permitirAgregar && (
        <Button type="button" variant="outline" size="sm" onClick={() => append(valorNuevaLinea as never)}>
          <Plus className="size-4" />
          {etiquetaAgregar}
        </Button>
      )}
    </div>
  )
}

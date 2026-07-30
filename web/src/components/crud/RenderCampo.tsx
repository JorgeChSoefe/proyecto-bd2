import { Controller, type Control, type FieldValues } from 'react-hook-form'
import { Combobox } from '@/components/forms/Combobox'
import { Field, FieldDescription, FieldError, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select'
import { Switch } from '@/components/ui/switch'
import { Textarea } from '@/components/ui/textarea'
import { cn } from '@/lib/utils'
import type { CampoConfig, TipoCampo } from './crud-config'

function tipoInputHtml(tipo: TipoCampo): string {
  switch (tipo) {
    case 'email':
      return 'email'
    case 'telefono':
      return 'tel'
    case 'url':
      return 'url'
    default:
      return 'text'
  }
}

/** Switch por tipo de campo -- lo usa CrudFormDialog y cualquier form a medida que quiera el mismo look & feel. */
export function RenderCampo<TForm extends FieldValues>({ campo, control }: { campo: CampoConfig<TForm>; control: Control<TForm> }) {
  return (
    <Controller
      name={campo.name}
      control={control}
      render={({ field, fieldState }) => (
        <Field data-invalid={fieldState.invalid} className={cn(campo.colSpan === 2 && 'sm:col-span-2')}>
          <FieldLabel htmlFor={campo.name}>
            {campo.label}
            {campo.requerido && <span className="text-destructive"> *</span>}
          </FieldLabel>

          {(campo.tipo === 'texto' || campo.tipo === 'email' || campo.tipo === 'telefono' || campo.tipo === 'url') && (
            <Input
              {...field}
              value={(field.value as string) ?? ''}
              id={campo.name}
              type={tipoInputHtml(campo.tipo)}
              placeholder={campo.placeholder}
              disabled={campo.deshabilitado}
              autoFocus={campo.autoFocus}
              aria-invalid={fieldState.invalid}
            />
          )}

          {campo.tipo === 'password' && (
            <Input
              {...field}
              value={(field.value as string) ?? ''}
              id={campo.name}
              type="password"
              placeholder={campo.placeholder}
              autoFocus={campo.autoFocus}
              aria-invalid={fieldState.invalid}
            />
          )}

          {campo.tipo === 'textarea' && (
            <Textarea
              {...field}
              value={(field.value as string) ?? ''}
              id={campo.name}
              placeholder={campo.placeholder}
              disabled={campo.deshabilitado}
              aria-invalid={fieldState.invalid}
            />
          )}

          {campo.tipo === 'numero' && (
            <Input
              {...field}
              value={(field.value as number | string) ?? ''}
              id={campo.name}
              type="number"
              placeholder={campo.placeholder}
              disabled={campo.deshabilitado}
              aria-invalid={fieldState.invalid}
            />
          )}

          {campo.tipo === 'moneda' && (
            <Input
              {...field}
              value={(field.value as number | string) ?? ''}
              id={campo.name}
              type="number"
              step="0.01"
              placeholder={campo.placeholder}
              disabled={campo.deshabilitado}
              aria-invalid={fieldState.invalid}
            />
          )}

          {campo.tipo === 'fecha' && (
            <Input
              {...field}
              value={(field.value as string) ?? ''}
              id={campo.name}
              type="date"
              disabled={campo.deshabilitado}
              aria-invalid={fieldState.invalid}
            />
          )}

          {campo.tipo === 'switch' && (
            <Switch id={campo.name} checked={!!field.value} onCheckedChange={field.onChange} disabled={campo.deshabilitado} />
          )}

          {campo.tipo === 'select' && (
            <Select
              value={field.value != null ? String(field.value) : undefined}
              onValueChange={(v) => {
                const opcion = campo.opciones?.find((o) => String(o.valor) === v)
                field.onChange(opcion ? opcion.valor : v)
              }}
              disabled={campo.deshabilitado}
            >
              <SelectTrigger id={campo.name} className="w-full" aria-invalid={fieldState.invalid}>
                <SelectValue placeholder={campo.placeholder} />
              </SelectTrigger>
              <SelectContent>
                {campo.opciones?.map((o) => (
                  <SelectItem key={o.valor} value={String(o.valor)}>
                    {o.etiqueta}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          )}

          {campo.tipo === 'lookup' && campo.lookup && (
            <Combobox
              lookup={campo.lookup}
              value={field.value as number | null}
              onChange={field.onChange}
              placeholder={campo.placeholder}
              disabled={campo.deshabilitado}
            />
          )}

          {campo.ayuda && !fieldState.invalid && <FieldDescription>{campo.ayuda}</FieldDescription>}
          {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
        </Field>
      )}
    />
  )
}

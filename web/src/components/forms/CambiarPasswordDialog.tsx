import { zodResolver } from '@hookform/resolvers/zod'
import { useState } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { z } from 'zod'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { apiFetch } from '@/lib/api/client'
import { aplicarErroresServidor } from '@/lib/api/problem-details'
import { useAuth } from '@/lib/auth/auth-context'

// El endpoint (POST /api/usuarios/{id}/cambiar-password) solo permite
// cambiar la PROPIA contrasena -- el servidor rechaza con 403 si el id no es
// el del usuario autenticado. No existe un endpoint para que un admin
// resetee la password de otro usuario; por eso este dialog vive aca (uso
// exclusivo de auto-servicio desde el Topbar) y no como accion por fila en
// el CRUD de Usuarios.
const schema = z
  .object({
    passwordActual: z.string().min(1, 'Requerido'),
    passwordNueva: z.string().min(8, 'Minimo 8 caracteres'),
    confirmar: z.string().min(1, 'Requerido'),
  })
  .refine((v) => v.passwordNueva === v.confirmar, { message: 'Las contrasenas no coinciden', path: ['confirmar'] })

type FormValues = z.infer<typeof schema>

export function CambiarPasswordDialog({ open, onOpenChange }: { open: boolean; onOpenChange: (open: boolean) => void }) {
  const { sesion } = useAuth()
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)
  const form = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { passwordActual: '', passwordNueva: '', confirmar: '' },
  })

  if (!sesion) return null

  const onSubmit = form.handleSubmit(async (valores) => {
    setErrorGeneral(null)
    try {
      await apiFetch(`/usuarios/${sesion.idUsuario}/cambiar-password`, {
        method: 'POST',
        body: { passwordActual: valores.passwordActual, passwordNueva: valores.passwordNueva },
      })
      toast.success('Contrasena actualizada.')
      form.reset()
      onOpenChange(false)
    } catch (err) {
      setErrorGeneral(aplicarErroresServidor(err, form, ['passwordActual', 'passwordNueva']))
    }
  })

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Cambiar contrasena</DialogTitle>
          <DialogDescription>Vas a cambiar la contrasena de tu propia cuenta ({sesion.nombreUsuario}).</DialogDescription>
        </DialogHeader>
        <form onSubmit={onSubmit} noValidate>
          <FieldGroup>
            <Controller
              name="passwordActual"
              control={form.control}
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor={field.name}>Contrasena actual</FieldLabel>
                  <Input {...field} id={field.name} type="password" autoFocus aria-invalid={fieldState.invalid} />
                  {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                </Field>
              )}
            />
            <Controller
              name="passwordNueva"
              control={form.control}
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor={field.name}>Contrasena nueva</FieldLabel>
                  <Input {...field} id={field.name} type="password" aria-invalid={fieldState.invalid} />
                  {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                </Field>
              )}
            />
            <Controller
              name="confirmar"
              control={form.control}
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor={field.name}>Confirmar contrasena nueva</FieldLabel>
                  <Input {...field} id={field.name} type="password" aria-invalid={fieldState.invalid} />
                  {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                </Field>
              )}
            />
            <AlertaFormulario mensaje={errorGeneral} />
          </FieldGroup>
          <DialogFooter className="mt-4">
            <Button type="button" variant="outline" onClick={() => onOpenChange(false)}>
              Cancelar
            </Button>
            <Button type="submit" disabled={form.formState.isSubmitting}>
              {form.formState.isSubmitting ? 'Guardando...' : 'Guardar'}
            </Button>
          </DialogFooter>
        </form>
      </DialogContent>
    </Dialog>
  )
}

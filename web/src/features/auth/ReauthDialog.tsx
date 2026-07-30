import { zodResolver } from '@hookform/resolvers/zod'
import { useState } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { z } from 'zod'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { useAuth } from '@/lib/auth/auth-context'

const schema = z.object({ password: z.string().min(1, 'Requerido') })
type FormValues = z.infer<typeof schema>

/**
 * Modal NO descartable: aparece cuando expira la sesion o ante cualquier
 * 401. A proposito no es un redirect a /login -- preserva cualquier
 * formulario que este a medio llenar (ej. una venta con varias lineas). Solo
 * refresca el token; nunca reintenta la mutacion que estaba en curso (eso lo
 * decide el usuario, para no duplicar una venta/compra).
 */
export function ReauthDialog() {
  const { sesion, sesionExpirada, reautenticar, logout } = useAuth()
  const [error, setError] = useState<string | null>(null)

  const form = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: { password: '' } })

  if (!sesionExpirada || !sesion) return null

  const onSubmit = form.handleSubmit(async (valores) => {
    setError(null)
    try {
      await reautenticar(valores.password)
      form.reset()
    } catch {
      setError('Contrasena incorrecta.')
    }
  })

  return (
    <Dialog open>
      <DialogContent showCloseButton={false} onEscapeKeyDown={(e) => e.preventDefault()} onPointerDownOutside={(e) => e.preventDefault()}>
        <DialogHeader>
          <DialogTitle>Tu sesion expiro</DialogTitle>
          <DialogDescription>
            Volve a ingresar tu contrasena para continuar como <strong>{sesion.nombreUsuario}</strong>. Nada de lo que
            tenias en pantalla se perdio.
          </DialogDescription>
        </DialogHeader>
        <form onSubmit={onSubmit} noValidate>
          <FieldGroup>
            <Controller
              name="password"
              control={form.control}
              render={({ field, fieldState }) => (
                <Field data-invalid={fieldState.invalid}>
                  <FieldLabel htmlFor={field.name}>Contrasena</FieldLabel>
                  <Input {...field} id={field.name} type="password" autoFocus aria-invalid={fieldState.invalid} />
                  {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                </Field>
              )}
            />
            <AlertaFormulario mensaje={error} />
            <div className="flex justify-end gap-2">
              <Button type="button" variant="ghost" onClick={logout}>
                Cerrar sesion
              </Button>
              <Button type="submit" disabled={form.formState.isSubmitting}>
                {form.formState.isSubmitting ? 'Verificando...' : 'Continuar'}
              </Button>
            </div>
          </FieldGroup>
        </form>
      </DialogContent>
    </Dialog>
  )
}

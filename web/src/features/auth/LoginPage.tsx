import { zodResolver } from '@hookform/resolvers/zod'
import { useState } from 'react'
import { Controller, useForm } from 'react-hook-form'
import { Navigate, useLocation, useNavigate } from 'react-router'
import { z } from 'zod'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { Button } from '@/components/ui/button'
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card'
import { Field, FieldError, FieldGroup, FieldLabel } from '@/components/ui/field'
import { Input } from '@/components/ui/input'
import { ApiError } from '@/lib/api/client'
import { useAuth } from '@/lib/auth/auth-context'

const loginSchema = z.object({
  nombreUsuario: z.string().trim().min(1, 'Requerido'),
  password: z.string().min(1, 'Requerido'),
})

type LoginForm = z.infer<typeof loginSchema>

export function LoginPage() {
  const { sesion, login } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)

  const form = useForm<LoginForm>({
    resolver: zodResolver(loginSchema),
    defaultValues: { nombreUsuario: '', password: '' },
  })

  if (sesion) {
    const volverA = (location.state as { volverA?: string } | null)?.volverA ?? '/'
    return <Navigate to={volverA} replace />
  }

  const onSubmit = form.handleSubmit(async (valores) => {
    setErrorGeneral(null)
    try {
      await login(valores.nombreUsuario, valores.password)
      const volverA = (location.state as { volverA?: string } | null)?.volverA ?? '/'
      navigate(volverA, { replace: true })
    } catch (err) {
      if (err instanceof ApiError && err.status === 401) {
        setErrorGeneral('Usuario o contrasena invalidos.')
      } else {
        setErrorGeneral('No se pudo iniciar sesion. Intenta de nuevo.')
      }
    }
  })

  return (
    <div className="flex min-h-svh items-center justify-center p-4">
      <Card className="w-full max-w-sm">
        <CardHeader>
          <CardTitle>FarmaRed 24/7</CardTitle>
          <CardDescription>Ingresa tus credenciales para continuar.</CardDescription>
        </CardHeader>
        <CardContent>
          <form onSubmit={onSubmit} noValidate>
            <FieldGroup>
              <Controller
                name="nombreUsuario"
                control={form.control}
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel htmlFor={field.name}>Usuario</FieldLabel>
                    <Input {...field} id={field.name} autoFocus autoComplete="username" aria-invalid={fieldState.invalid} />
                    {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                  </Field>
                )}
              />
              <Controller
                name="password"
                control={form.control}
                render={({ field, fieldState }) => (
                  <Field data-invalid={fieldState.invalid}>
                    <FieldLabel htmlFor={field.name}>Contrasena</FieldLabel>
                    <Input {...field} id={field.name} type="password" autoComplete="current-password" aria-invalid={fieldState.invalid} />
                    {fieldState.invalid && <FieldError errors={[fieldState.error]} />}
                  </Field>
                )}
              />
              <AlertaFormulario mensaje={errorGeneral} />
              <Button type="submit" disabled={form.formState.isSubmitting} className="w-full">
                {form.formState.isSubmitting ? 'Ingresando...' : 'Ingresar'}
              </Button>
            </FieldGroup>
          </form>
        </CardContent>
      </Card>
    </div>
  )
}

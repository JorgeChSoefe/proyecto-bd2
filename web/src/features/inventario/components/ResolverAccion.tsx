import { useMutation, useQueryClient } from '@tanstack/react-query'
import { Check } from 'lucide-react'
import { toast } from 'sonner'
import { Button } from '@/components/ui/button'
import { apiFetch, ApiError } from '@/lib/api/client'
import { invalidarTrasResolverAlerta } from '@/lib/api/invalidaciones'
import { useCan } from '@/lib/auth/use-can'
import type { AlertaStock } from '@/types/api'

export function ResolverAccion({ alerta }: { alerta: AlertaStock }) {
  const { can } = useCan()
  const qc = useQueryClient()
  const resolver = useMutation({
    mutationFn: () => apiFetch(`/inventario/alertas/${alerta.idAlerta}/resolver`, { method: 'PATCH' }),
    onSuccess: () => {
      invalidarTrasResolverAlerta(qc)
      toast.success('Alerta resuelta.')
    },
    onError: (err) => toast.error(err instanceof ApiError ? (err.problem?.detail ?? err.message) : 'No se pudo resolver la alerta.'),
  })

  if (alerta.resuelta || !can('inventario:resolver_alerta')) return null

  return (
    <Button variant="outline" size="sm" onClick={() => resolver.mutate()} disabled={resolver.isPending}>
      <Check className="size-4" />
      Resolver
    </Button>
  )
}

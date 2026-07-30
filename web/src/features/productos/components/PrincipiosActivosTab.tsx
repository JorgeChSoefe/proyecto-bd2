import { zodResolver } from '@hookform/resolvers/zod'
import { useQueryClient } from '@tanstack/react-query'
import { useForm, type Resolver } from 'react-hook-form'
import { Trash2 } from 'lucide-react'
import { toast } from 'sonner'
import { z } from 'zod'
import type { CampoConfig } from '@/components/crud/crud-config'
import { RenderCampo } from '@/components/crud/RenderCampo'
import { EstadoVacio } from '@/components/feedback/EstadoVacio'
import { Button } from '@/components/ui/button'
import { FieldGroup } from '@/components/ui/field'
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table'
import { apiFetch, ApiError } from '@/lib/api/client'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import { zId, zTextoReq } from '@/lib/validation'
import type { Medicamento, MedicamentoPrincipio } from '@/types/api'

const agregarSchema = z.object({
  idPrincipio: zId,
  cantidadPorDosis: z.coerce.number().positive('Debe ser mayor a cero'),
  unidad: zTextoReq(50),
})

type AgregarForm = z.infer<typeof agregarSchema>

const CAMPOS: CampoConfig<AgregarForm>[] = [
  {
    name: 'idPrincipio',
    label: 'Principio activo',
    tipo: 'lookup',
    requerido: true,
    lookup: { recurso: 'principios-activos', endpoint: '/principios-activos', campoId: 'idPrincipio', campoEtiqueta: 'nombreInn' },
  },
  { name: 'cantidadPorDosis', label: 'Cantidad por dosis', tipo: 'numero', requerido: true },
  { name: 'unidad', label: 'Unidad', tipo: 'texto', requerido: true, placeholder: 'mg, ml, %...' },
]

const VALORES_DEFECTO: AgregarForm = { idPrincipio: undefined as unknown as number, cantidadPorDosis: undefined as unknown as number, unidad: '' }

interface Props {
  idProducto: number
  medicamento: Medicamento | null
  principios: MedicamentoPrincipio[]
}

export function PrincipiosActivosTab({ idProducto, medicamento, principios }: Props) {
  const qc = useQueryClient()
  const { can } = useCan()
  const puedeEditar = can('medicamentos:editar')

  // Cast necesario: zId usa z.coerce, asi que zodResolver infiere un
  // Resolver<Input,_,Output> distinto del que espera useForm -- misma
  // limitacion que en CrudFormDialog.tsx.
  const form = useForm<AgregarForm>({
    resolver: zodResolver(agregarSchema) as unknown as Resolver<AgregarForm>,
    defaultValues: VALORES_DEFECTO,
  })

  if (!medicamento) {
    return <EstadoVacio titulo="Primero crea la ficha clinica" descripcion="Los principios activos se asocian a la ficha clinica del producto, en la otra pestana." />
  }

  const invalidar = () => qc.invalidateQueries({ queryKey: qk.productos.detalle(idProducto) })

  const onSubmit = form.handleSubmit(async (valores) => {
    try {
      await apiFetch(`/medicamentos/${medicamento.idMedicamento}/principios`, { method: 'POST', body: valores })
      await invalidar()
      toast.success('Principio activo agregado.')
      form.reset(VALORES_DEFECTO)
    } catch (err) {
      toast.error(err instanceof ApiError ? (err.problem?.detail ?? err.message) : 'No se pudo agregar el principio activo.')
    }
  })

  const quitar = async (idPrincipio: number) => {
    try {
      await apiFetch(`/medicamentos/${medicamento.idMedicamento}/principios/${idPrincipio}`, { method: 'DELETE' })
      await invalidar()
      toast.success('Principio activo quitado.')
    } catch (err) {
      toast.error(err instanceof ApiError ? (err.problem?.detail ?? err.message) : 'No se pudo quitar el principio activo.')
    }
  }

  return (
    <div className="space-y-4">
      {principios.length === 0 ? (
        <EstadoVacio titulo="Sin principios activos asignados" />
      ) : (
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Principio activo</TableHead>
              <TableHead>Grupo terapeutico</TableHead>
              <TableHead>Cantidad por dosis</TableHead>
              <TableHead>Unidad</TableHead>
              {puedeEditar && <TableHead />}
            </TableRow>
          </TableHeader>
          <TableBody>
            {principios.map((p) => (
              <TableRow key={p.idPrincipio}>
                <TableCell>{p.nombreInn}</TableCell>
                <TableCell>{p.grupoTerapeutico ?? '--'}</TableCell>
                <TableCell>{p.cantidadPorDosis ?? '--'}</TableCell>
                <TableCell>{p.unidad ?? '--'}</TableCell>
                {puedeEditar && (
                  <TableCell>
                    <Button variant="ghost" size="icon" aria-label={`Quitar ${p.nombreInn}`} onClick={() => quitar(p.idPrincipio)}>
                      <Trash2 className="size-4" />
                    </Button>
                  </TableCell>
                )}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      )}

      {puedeEditar && (
        <form onSubmit={onSubmit} noValidate className="rounded-md border p-4">
          <p className="mb-3 text-sm font-medium">Agregar principio activo</p>
          <FieldGroup className="grid grid-cols-1 items-start gap-4 sm:grid-cols-3">
            {CAMPOS.map((campo) => (
              <RenderCampo key={String(campo.name)} campo={campo} control={form.control} />
            ))}
          </FieldGroup>
          <Button type="submit" className="mt-3" disabled={form.formState.isSubmitting}>
            {form.formState.isSubmitting ? 'Agregando...' : 'Agregar'}
          </Button>
        </form>
      )}
    </div>
  )
}

import { zodResolver } from '@hookform/resolvers/zod'
import { useEffect, useState } from 'react'
import { useForm, type Resolver } from 'react-hook-form'
import { useQueryClient } from '@tanstack/react-query'
import { toast } from 'sonner'
import { z } from 'zod'
import type { CampoConfig } from '@/components/crud/crud-config'
import { RenderCampo } from '@/components/crud/RenderCampo'
import { AlertaFormulario } from '@/components/feedback/AlertaFormulario'
import { Button } from '@/components/ui/button'
import { Dialog, DialogContent, DialogFooter, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { FieldGroup } from '@/components/ui/field'
import { apiFetch } from '@/lib/api/client'
import { aplicarErroresServidor } from '@/lib/api/problem-details'
import { qk } from '@/lib/api/query-keys'
import { zTextoOpc } from '@/lib/validation'
import type { Medicamento, ViaAdministracion } from '@/types/api'
import { VIA_ADMINISTRACION_OPCIONES } from '../constants'

const fichaSchema = z.object({
  concentracion: zTextoOpc(255),
  viaAdministracion: z.enum(
    VIA_ADMINISTRACION_OPCIONES.map((o) => o.valor) as [ViaAdministracion, ...ViaAdministracion[]],
    { message: 'Selecciona una via de administracion' },
  ),
  condicionesAlmacenamiento: zTextoOpc(1000),
  controlado: z.boolean(),
  numeroRegistroSanitario: zTextoOpc(255),
  indicaciones: zTextoOpc(2000),
  contraindicaciones: zTextoOpc(2000),
  efectosSecundarios: zTextoOpc(2000),
  interacciones: zTextoOpc(2000),
})

type FichaForm = z.infer<typeof fichaSchema>

// POST /productos/{id}/medicamento y PUT /medicamentos/{id} comparten
// exactamente este shape (MedicamentoUpdateRequest en el backend) -- un solo
// formulario sirve para crear y editar la ficha.
const CAMPOS: CampoConfig<FichaForm>[] = [
  { name: 'concentracion', label: 'Concentracion', tipo: 'texto', placeholder: 'Ej. 500mg', autoFocus: true },
  { name: 'viaAdministracion', label: 'Via de administracion', tipo: 'select', requerido: true, opciones: VIA_ADMINISTRACION_OPCIONES },
  { name: 'numeroRegistroSanitario', label: 'Registro sanitario', tipo: 'texto', colSpan: 2 },
  { name: 'condicionesAlmacenamiento', label: 'Condiciones de almacenamiento', tipo: 'texto', colSpan: 2 },
  {
    name: 'controlado',
    label: 'Medicamento controlado',
    tipo: 'switch',
    colSpan: 2,
    ayuda: 'Ademas de "requiere receta" del producto, exige una receta vigente y sin dispensar al vender (ver Fase 7).',
  },
  { name: 'indicaciones', label: 'Indicaciones', tipo: 'textarea', colSpan: 2 },
  { name: 'contraindicaciones', label: 'Contraindicaciones', tipo: 'textarea', colSpan: 2 },
  { name: 'efectosSecundarios', label: 'Efectos secundarios', tipo: 'textarea', colSpan: 2 },
  { name: 'interacciones', label: 'Interacciones', tipo: 'textarea', colSpan: 2 },
]

const VALORES_DEFECTO: FichaForm = {
  concentracion: undefined,
  viaAdministracion: 'oral',
  condicionesAlmacenamiento: undefined,
  controlado: false,
  numeroRegistroSanitario: undefined,
  indicaciones: undefined,
  contraindicaciones: undefined,
  efectosSecundarios: undefined,
  interacciones: undefined,
}

function aFormulario(m: Medicamento): FichaForm {
  return {
    concentracion: m.concentracion ?? undefined,
    viaAdministracion: m.viaAdministracion,
    condicionesAlmacenamiento: m.condicionesAlmacenamiento ?? undefined,
    controlado: m.controlado,
    numeroRegistroSanitario: m.numeroRegistroSanitario ?? undefined,
    indicaciones: m.indicaciones ?? undefined,
    contraindicaciones: m.contraindicaciones ?? undefined,
    efectosSecundarios: m.efectosSecundarios ?? undefined,
    interacciones: m.interacciones ?? undefined,
  }
}

interface Props {
  idProducto: number
  medicamento: Medicamento | null
  open: boolean
  onOpenChange: (open: boolean) => void
}

/** Crea (POST /productos/{id}/medicamento) o edita (PUT /medicamentos/{id}) la ficha clinica de un producto. */
export function FichaMedicamentoDialog({ idProducto, medicamento, open, onOpenChange }: Props) {
  const qc = useQueryClient()
  const [errorGeneral, setErrorGeneral] = useState<string | null>(null)
  // Cast necesario: zTextoOpc usa .transform(), asi que zodResolver infiere un
  // Resolver<Input,_,Output> donde Input y Output difieren en opcionalidad de
  // claves -- misma limitacion que en CrudFormDialog.tsx.
  const form = useForm<FichaForm>({ resolver: zodResolver(fichaSchema) as unknown as Resolver<FichaForm>, defaultValues: VALORES_DEFECTO })

  useEffect(() => {
    if (!open) return
    form.reset(medicamento ? aFormulario(medicamento) : VALORES_DEFECTO)
    setErrorGeneral(null)
    // Solo al abrir/cambiar de medicamento -- form es estable entre renders.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, medicamento])

  const onSubmit = form.handleSubmit(async (valores) => {
    setErrorGeneral(null)
    try {
      if (medicamento) await apiFetch(`/medicamentos/${medicamento.idMedicamento}`, { method: 'PUT', body: valores })
      else await apiFetch(`/productos/${idProducto}/medicamento`, { method: 'POST', body: valores })
      await qc.invalidateQueries({ queryKey: qk.productos.detalle(idProducto) })
      toast.success(medicamento ? 'Ficha clinica actualizada.' : 'Ficha clinica creada.')
      onOpenChange(false)
    } catch (err) {
      setErrorGeneral(aplicarErroresServidor(err, form, CAMPOS.map((c) => String(c.name))))
    }
  })

  return (
    <Dialog open={open} onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[85vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>{medicamento ? 'Editar ficha clinica' : 'Crear ficha clinica'}</DialogTitle>
        </DialogHeader>
        <form onSubmit={onSubmit} noValidate>
          <FieldGroup className="grid grid-cols-1 gap-4 sm:grid-cols-2">
            {CAMPOS.map((campo) => (
              <RenderCampo key={String(campo.name)} campo={campo} control={form.control} />
            ))}
          </FieldGroup>
          <div className="mt-4">
            <AlertaFormulario mensaje={errorGeneral} />
          </div>
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

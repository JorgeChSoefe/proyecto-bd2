import { useState } from 'react'
import { Pencil, Plus } from 'lucide-react'
import { EstadoVacio } from '@/components/feedback/EstadoVacio'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { useCan } from '@/lib/auth/use-can'
import type { Medicamento } from '@/types/api'
import { VIA_ADMINISTRACION_OPCIONES } from '../constants'
import { FichaMedicamentoDialog } from './FichaMedicamentoDialog'

function Campo({ label, value }: { label: string; value: string | null | undefined }) {
  return (
    <div>
      <p className="text-muted-foreground text-xs">{label}</p>
      <p className="text-sm">{value?.trim() ? value : '--'}</p>
    </div>
  )
}

export function FichaClinicaTab({ idProducto, medicamento }: { idProducto: number; medicamento: Medicamento | null }) {
  const { can } = useCan()
  const [open, setOpen] = useState(false)
  const etiquetaVia = VIA_ADMINISTRACION_OPCIONES.find((o) => o.valor === medicamento?.viaAdministracion)?.etiqueta

  if (!medicamento) {
    return (
      <>
        <EstadoVacio
          titulo="Este producto no tiene ficha clinica"
          descripcion="La ficha clinica guarda via de administracion, indicaciones y si el medicamento es controlado."
          accion={
            can('medicamentos:crear') && (
              <Button onClick={() => setOpen(true)}>
                <Plus className="size-4" />
                Crear ficha clinica
              </Button>
            )
          }
        />
        <FichaMedicamentoDialog idProducto={idProducto} medicamento={null} open={open} onOpenChange={setOpen} />
      </>
    )
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-end">
        {can('medicamentos:editar') && (
          <Button variant="outline" onClick={() => setOpen(true)}>
            <Pencil className="size-4" />
            Editar ficha
          </Button>
        )}
      </div>

      <div className="grid grid-cols-1 gap-4 rounded-md border p-4 sm:grid-cols-2">
        <Campo label="Concentracion" value={medicamento.concentracion} />
        <Campo label="Via de administracion" value={etiquetaVia ?? medicamento.viaAdministracion} />
        <Campo label="Registro sanitario" value={medicamento.numeroRegistroSanitario} />
        <div>
          <p className="text-muted-foreground text-xs">Controlado</p>
          <Badge variant={medicamento.controlado ? 'destructive' : 'secondary'}>{medicamento.controlado ? 'Si' : 'No'}</Badge>
        </div>
        <div className="sm:col-span-2">
          <Campo label="Condiciones de almacenamiento" value={medicamento.condicionesAlmacenamiento} />
        </div>
        <div className="sm:col-span-2">
          <Campo label="Indicaciones" value={medicamento.indicaciones} />
        </div>
        <div className="sm:col-span-2">
          <Campo label="Contraindicaciones" value={medicamento.contraindicaciones} />
        </div>
        <div className="sm:col-span-2">
          <Campo label="Efectos secundarios" value={medicamento.efectosSecundarios} />
        </div>
        <div className="sm:col-span-2">
          <Campo label="Interacciones" value={medicamento.interacciones} />
        </div>
      </div>

      <FichaMedicamentoDialog idProducto={idProducto} medicamento={medicamento} open={open} onOpenChange={setOpen} />
    </div>
  )
}

import { useMemo, useState } from 'react'
import type { ColumnDef } from '@tanstack/react-table'
import type { FieldValues } from 'react-hook-form'
import { Pencil, Plus, Trash2 } from 'lucide-react'
import { useNavigate } from 'react-router'
import { PageHeader } from '@/components/layout/PageHeader'
import { SinPermiso } from '@/components/feedback/SinPermiso'
import { DataTable } from '@/components/data-table/DataTable'
import { Paginacion } from '@/components/data-table/Paginacion'
import { Button } from '@/components/ui/button'
import type { CrudConfig, CrudCtx } from './crud-config'
import { CrudDeleteDialog } from './CrudDeleteDialog'
import { CrudFormDialog } from './CrudFormDialog'
import { ToolbarFiltros } from './ToolbarFiltros'
import { useCrud } from './use-crud'

/** Renderiza un modulo entero (lista + crear + editar + eliminar) desde un solo CrudConfig -- ver §3 del plan. */
export function CrudPage<TRow, TForm extends FieldValues>({ config }: { config: CrudConfig<TRow, TForm> }) {
  const { tabla, lista, crear, actualizar, eliminar, permisos } = useCrud(config)
  const navigate = useNavigate()
  const [dialogoAbierto, setDialogoAbierto] = useState(false)
  const [filaEditar, setFilaEditar] = useState<TRow | null>(null)
  const [filaEliminar, setFilaEliminar] = useState<TRow | null>(null)

  const abrirCrear = () => {
    setFilaEditar(null)
    setDialogoAbierto(true)
  }
  const abrirEditar = (row: TRow) => {
    setFilaEditar(row)
    setDialogoAbierto(true)
  }

  const ctx: CrudCtx<TRow> = { recargar: () => void lista.refetch(), abrirEditar, abrirCrear }

  const columnas = useMemo<ColumnDef<TRow>[]>(() => {
    if (!permisos.editar && !permisos.eliminar && !config.acciones) return config.columnas
    return [
      ...config.columnas,
      {
        id: '__acciones__',
        header: '',
        cell: ({ row }) => (
          // stopPropagation: si la fila es clickeable (rutaDetalle), un clic en estos
          // botones no debe tambien disparar la navegacion de la fila.
          <div className="flex justify-end gap-1" onClick={(e) => e.stopPropagation()}>
            {config.acciones?.(row.original, ctx)}
            {permisos.editar && (
              <Button variant="ghost" size="icon" onClick={() => abrirEditar(row.original)} aria-label="Editar">
                <Pencil className="size-4" />
              </Button>
            )}
            {permisos.eliminar && (
              <Button variant="ghost" size="icon" onClick={() => setFilaEliminar(row.original)} aria-label={config.etiquetaEliminar ?? 'Eliminar'}>
                <Trash2 className="size-4" />
              </Button>
            )}
          </div>
        ),
      },
    ]
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [config, permisos.editar, permisos.eliminar])

  if (!permisos.listar) return <SinPermiso />

  return (
    <div>
      <PageHeader
        titulo={config.titulo}
        acciones={
          <>
            {config.accionesGlobales?.(ctx)}
            {permisos.crear && (
              <Button onClick={abrirCrear}>
                <Plus className="size-4" />
                Nuevo
              </Button>
            )}
          </>
        }
      />

      <div className="mb-4">
        <ToolbarFiltros
          busqueda={tabla.busqueda}
          onBusquedaChange={tabla.setBusqueda}
          filtros={config.filtros}
          obtenerFiltro={tabla.obtenerFiltro}
          onFiltroChange={tabla.setFiltro}
          sinBusqueda={config.sinBusqueda}
        />
      </div>

      <DataTable
        columnas={columnas}
        datos={lista.data?.items ?? []}
        cargando={lista.isLoading}
        esPlaceholder={lista.isPlaceholderData}
        getId={config.getId}
        claseFila={config.claseFila}
        vacio={config.vacio}
        onFilaClick={config.rutaDetalle ? (row) => navigate(config.rutaDetalle!(row)) : undefined}
      />

      {lista.data && (
        <Paginacion
          pagina={tabla.pagina}
          tamano={tabla.tamano}
          total={lista.data.total}
          onPaginaChange={tabla.setPagina}
          deshabilitada={lista.isPlaceholderData}
        />
      )}

      {(permisos.crear || permisos.editar) && (
        <CrudFormDialog
          config={config}
          open={dialogoAbierto}
          onOpenChange={setDialogoAbierto}
          filaEditar={filaEditar}
          onCrear={(body) => crear.mutateAsync(body)}
          onActualizar={(args) => actualizar.mutateAsync(args)}
          enviando={crear.isPending || actualizar.isPending}
        />
      )}

      {permisos.eliminar && (
        <CrudDeleteDialog
          config={config}
          fila={filaEliminar}
          onOpenChange={(open) => !open && setFilaEliminar(null)}
          onEliminar={(id) => eliminar.mutateAsync(id)}
        />
      )}
    </div>
  )
}

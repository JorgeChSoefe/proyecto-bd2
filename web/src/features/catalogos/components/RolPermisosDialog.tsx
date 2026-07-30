import { useState } from 'react'
import { useQuery, useQueryClient } from '@tanstack/react-query'
import { KeyRound } from 'lucide-react'
import { Button } from '@/components/ui/button'
import { Checkbox } from '@/components/ui/checkbox'
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from '@/components/ui/dialog'
import { Skeleton } from '@/components/ui/skeleton'
import { apiFetch } from '@/lib/api/client'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import type { Paginado } from '@/types/pagination'
import type { Permiso, Rol } from '@/types/api'

/**
 * Boton "Permisos" por fila de Roles -- matriz modulo x accion contra el
 * estado real de asignacion (GET .../permisos, Fase 0 de este build). El
 * chequeo de permiso es sobre el modulo "permisos" (ver/editar), no "roles":
 * PermisosController.TienePermiso vive con modulo "permisos" (ver PermisosController.cs).
 */
export function RolPermisosAction({ rol }: { rol: Rol }) {
  const { can } = useCan()
  const [open, setOpen] = useState(false)

  if (!can('permisos:listar')) return null

  return (
    <>
      <Button variant="ghost" size="icon" onClick={() => setOpen(true)} aria-label={`Permisos de ${rol.nombreRol}`}>
        <KeyRound className="size-4" />
      </Button>
      {open && <RolPermisosDialog rol={rol} onOpenChange={setOpen} />}
    </>
  )
}

function RolPermisosDialog({ rol, onOpenChange }: { rol: Rol; onOpenChange: (open: boolean) => void }) {
  const qc = useQueryClient()
  const { can } = useCan()
  const puedeEditar = can('permisos:editar')
  const claveAsignados = qk.usuarioPermisosDeRol(rol.idRol)

  // tamano=200 trae el catalogo completo de permisos en una sola pagina --
  // son ~70 filas fijas (11_Seed_Datos.sql), muy por debajo del tope real de 200.
  const { data: todos, isLoading: cargandoTodos } = useQuery({
    queryKey: [...qk.catalogo('permisos'), 'todos'],
    queryFn: () => apiFetch<Paginado<Permiso>>('/permisos?pagina=1&tamano=200'),
    staleTime: 5 * 60_000,
  })

  const { data: asignados, isLoading: cargandoAsignados } = useQuery({
    queryKey: claveAsignados,
    queryFn: () => apiFetch<Permiso[]>(`/roles/${rol.idRol}/permisos`),
  })

  const asignadosIds = new Set((asignados ?? []).map((p) => p.idPermiso))

  const toggle = async (permiso: Permiso, marcar: boolean) => {
    const anterior = asignados ?? []
    const optimista = marcar ? [...anterior, permiso] : anterior.filter((p) => p.idPermiso !== permiso.idPermiso)
    qc.setQueryData(claveAsignados, optimista) // UI optimista

    try {
      if (marcar) await apiFetch(`/roles/${rol.idRol}/permisos`, { method: 'POST', body: { idPermiso: permiso.idPermiso } })
      else await apiFetch(`/roles/${rol.idRol}/permisos/${permiso.idPermiso}`, { method: 'DELETE' })
    } catch {
      qc.setQueryData(claveAsignados, anterior) // rollback
    } finally {
      qc.invalidateQueries({ queryKey: claveAsignados })
    }
  }

  const porModulo = new Map<string, Permiso[]>()
  for (const p of todos?.items ?? []) {
    const lista = porModulo.get(p.modulo) ?? []
    lista.push(p)
    porModulo.set(p.modulo, lista)
  }
  const modulos = [...porModulo.entries()].sort(([a], [b]) => a.localeCompare(b))

  return (
    <Dialog open onOpenChange={onOpenChange}>
      <DialogContent className="max-h-[80vh] overflow-y-auto sm:max-w-2xl">
        <DialogHeader>
          <DialogTitle>Permisos de {rol.nombreRol}</DialogTitle>
          <DialogDescription>
            {puedeEditar ? 'Marca o desmarca para asignar/revocar de inmediato.' : 'Solo lectura -- no tienes permiso para editar.'}
          </DialogDescription>
        </DialogHeader>

        {cargandoTodos || cargandoAsignados ? (
          <div className="space-y-2">
            {Array.from({ length: 6 }).map((_, i) => (
              <Skeleton key={i} className="h-16 w-full" />
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-1 gap-3 sm:grid-cols-2">
            {modulos.map(([modulo, permisos]) => (
              <div key={modulo} className="rounded-md border p-3">
                <p className="mb-2 text-sm font-medium">{modulo}</p>
                <div className="space-y-1.5">
                  {permisos.map((p) => (
                    <label key={p.idPermiso} className="flex items-center gap-2 text-sm">
                      <Checkbox
                        checked={asignadosIds.has(p.idPermiso)}
                        disabled={!puedeEditar}
                        onCheckedChange={(v) => toggle(p, v === true)}
                      />
                      {p.accion}
                    </label>
                  ))}
                </div>
              </div>
            ))}
          </div>
        )}
      </DialogContent>
    </Dialog>
  )
}

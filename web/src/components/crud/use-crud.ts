import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import type { FieldValues } from 'react-hook-form'
import { createCrudApi } from '@/lib/api/crud-factory'
import { invalidarCatalogo } from '@/lib/api/invalidaciones'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import type { Permiso } from '@/lib/auth/permissions'
import { useTableParams } from '@/hooks/use-table-params'
import type { CrudConfig } from './crud-config'

export function useCrud<TRow, TForm extends FieldValues>(config: CrudConfig<TRow, TForm>) {
  const tabla = useTableParams({ sinBusqueda: config.sinBusqueda })
  const api = createCrudApi<TRow, TForm>(config.endpoint)
  const qc = useQueryClient()
  const { can } = useCan()

  // Filtros declarados en config.filtros (ej. idCategoria en Productos) viven en la
  // URL (ver ToolbarFiltros/useTableParams) pero no tienen un campo fijo en
  // ListaParams -- se leen aca por nombre y se agregan sueltos a la query.
  const filtrosActivos = Object.fromEntries(
    (config.filtros ?? [])
      .map((f) => [f.param, tabla.obtenerFiltro(f.param)] as const)
      .filter((entrada): entrada is [string, string] => entrada[1] !== undefined),
  )

  const lista = useQuery({
    queryKey: qk.catalogoLista(config.recurso, { pagina: tabla.pagina, tamano: tabla.tamano, busqueda: tabla.busqueda, ...filtrosActivos }),
    queryFn: ({ signal }) => api.listar({ pagina: tabla.pagina, tamano: tabla.tamano, busqueda: tabla.busqueda, ...filtrosActivos }, signal),
    placeholderData: keepPreviousData,
  })

  const invalidar = () => invalidarCatalogo(qc, config.recurso)

  const crear = useMutation({ mutationFn: api.crear, onSuccess: invalidar })
  const actualizar = useMutation({ mutationFn: api.actualizar, onSuccess: invalidar })
  const eliminar = useMutation({ mutationFn: api.eliminar, onSuccess: invalidar })

  return {
    tabla,
    lista,
    crear,
    actualizar,
    eliminar,
    permisos: {
      listar: can(`${config.modulo}:${config.accionListar ?? 'listar'}` as Permiso),
      crear: (config.permitirCrear ?? true) && can(`${config.modulo}:${config.accionCrear ?? 'crear'}` as Permiso),
      editar: (config.permitirEditar ?? true) && can(`${config.modulo}:${config.accionEditar ?? 'editar'}` as Permiso),
      eliminar: (config.permitirEliminar ?? true) && can(`${config.modulo}:${config.accionEliminar ?? 'eliminar'}` as Permiso),
    },
  }
}

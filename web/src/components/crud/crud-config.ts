import type { ColumnDef } from '@tanstack/react-table'
import type { ReactNode } from 'react'
import type { FieldValues, Path } from 'react-hook-form'
import type { ZodType } from 'zod'
import type { LookupConfig } from '@/hooks/use-lookups'
import type { Modulo } from '@/lib/auth/permissions'

export type TipoCampo =
  | 'texto'
  | 'textarea'
  | 'email'
  | 'telefono'
  | 'url'
  | 'password'
  | 'numero'
  | 'moneda'
  | 'fecha'
  | 'switch'
  | 'select'
  | 'lookup'

export interface OpcionSelect {
  valor: string | number
  etiqueta: string
}

export interface CampoConfig<TForm extends FieldValues> {
  name: Path<TForm>
  label: string
  tipo: TipoCampo
  placeholder?: string
  ayuda?: string
  requerido?: boolean
  colSpan?: 1 | 2
  opciones?: OpcionSelect[] // tipo 'select'
  lookup?: LookupConfig // tipo 'lookup'
  soloEnCrear?: boolean // ej. password/nombreUsuario de usuario
  soloEnEditar?: boolean
  deshabilitado?: boolean
  autoFocus?: boolean
}

export type FiltroConfig =
  | { tipo: 'select'; param: string; label: string; opciones: OpcionSelect[] }
  | { tipo: 'lookup'; param: string; label: string; lookup: LookupConfig }
  | { tipo: 'switch'; param: string; label: string }
  | { tipo: 'fecha'; param: string; label: string }

export interface CrudCtx<TRow> {
  recargar: () => void
  abrirEditar: (row: TRow) => void
  abrirCrear: () => void
}

export interface CrudConfig<TRow, TForm extends FieldValues> {
  // ---- identidad ----
  recurso: string // clave de cache y slug de ruta, ej. 'principios-activos'
  endpoint: string // '/principios-activos'
  modulo: Modulo // 'principios_activos' (guion bajo -- el permiso, no la ruta)
  titulo: string
  tituloSingular: string
  getId: (row: TRow) => number

  // ---- tabla ----
  columnas: ColumnDef<TRow>[]
  filtros?: FiltroConfig[]
  sinBusqueda?: boolean // endpoints sin `busqueda` (ej. recetas/pendientes)
  claseFila?: (row: TRow) => string | undefined
  vacio?: { titulo: string; descripcion?: string }
  /** Si se define, la fila entera navega a esta ruta al hacer clic (ej. Productos -> /productos/:id). */
  rutaDetalle?: (row: TRow) => string

  // ---- formulario ----
  campos: CampoConfig<TForm>[]
  schema: ZodType<TForm>
  schemaCrear?: ZodType<TForm>
  schemaEditar?: ZodType<TForm>
  valoresPorDefecto: TForm
  aFormulario: (row: TRow) => TForm
  anchoDialogo?: 'sm' | 'md' | 'lg'

  // ---- capacidades / extensiones ----
  permitirCrear?: boolean
  permitirEditar?: boolean
  permitirEliminar?: boolean
  // Nombre de accion de permiso cuando el modulo no sigue la convencion
  // listar/crear/editar/eliminar (ej. 'inventario' usa 'consultar' en vez de
  // 'listar' -- ver ACCIONES_POR_MODULO en lib/auth/permissions.ts).
  accionListar?: string
  accionCrear?: string
  accionEditar?: string
  accionEliminar?: string
  etiquetaEliminar?: string // 'Eliminar' | 'Desactivar'
  textoEliminar?: (row: TRow) => string
  acciones?: (row: TRow, ctx: CrudCtx<TRow>) => ReactNode
  accionesGlobales?: (ctx: CrudCtx<TRow>) => ReactNode
}

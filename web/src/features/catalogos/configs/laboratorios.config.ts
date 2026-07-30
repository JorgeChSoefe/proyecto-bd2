import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Laboratorio } from '@/types/api'
import { zEmailOpc, zTextoOpc, zTextoReq } from '@/lib/validation'

const laboratorioSchema = z.object({
  nombre: zTextoReq(255),
  paisOrigen: zTextoOpc(255),
  telefono: zTextoOpc(255),
  email: zEmailOpc,
  sitioWeb: zTextoOpc(255),
})

export type LaboratorioForm = z.infer<typeof laboratorioSchema>

export const laboratoriosConfig: CrudConfig<Laboratorio, LaboratorioForm> = {
  recurso: 'laboratorios',
  endpoint: '/laboratorios',
  modulo: 'laboratorios',
  titulo: 'Laboratorios',
  tituloSingular: 'Laboratorio',
  getId: (r) => r.idLaboratorio,

  columnas: [
    col.texto<Laboratorio>('nombre', 'Nombre'),
    col.texto<Laboratorio>('paisOrigen', 'Pais'),
    col.texto<Laboratorio>('telefono', 'Telefono'),
    col.enlace<Laboratorio>('sitioWeb', 'Sitio web'),
  ],

  campos: [
    { name: 'nombre', label: 'Nombre', tipo: 'texto', requerido: true, colSpan: 2, autoFocus: true },
    { name: 'paisOrigen', label: 'Pais de origen', tipo: 'texto' },
    { name: 'telefono', label: 'Telefono', tipo: 'telefono' },
    { name: 'email', label: 'Email', tipo: 'email' },
    { name: 'sitioWeb', label: 'Sitio web', tipo: 'url' },
  ],
  schema: laboratorioSchema,
  valoresPorDefecto: { nombre: '', paisOrigen: undefined, telefono: undefined, email: undefined, sitioWeb: undefined },
  aFormulario: (r) => ({
    nombre: r.nombre,
    paisOrigen: r.paisOrigen ?? undefined,
    telefono: r.telefono ?? undefined,
    email: r.email ?? undefined,
    sitioWeb: r.sitioWeb ?? undefined,
  }),

  textoEliminar: (r) => `Se eliminara el laboratorio "${r.nombre}". Esta accion no se puede deshacer.`,
}

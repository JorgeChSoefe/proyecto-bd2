import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Cliente } from '@/types/api'
import { zEmailOpc, zFechaISOOpc, zTextoOpc, zTextoReq } from '@/lib/validation'

const clienteSchema = z.object({
  nombreCompleto: zTextoReq(255),
  identificacion: zTextoReq(255),
  telefono: zTextoOpc(255),
  fechaNacimiento: zFechaISOOpc,
  email: zEmailOpc,
})

export type ClienteForm = z.infer<typeof clienteSchema>

export const clientesConfig: CrudConfig<Cliente, ClienteForm> = {
  recurso: 'clientes',
  endpoint: '/clientes',
  modulo: 'clientes',
  titulo: 'Clientes',
  tituloSingular: 'Cliente',
  getId: (r) => r.idCliente,

  columnas: [
    col.texto<Cliente>('nombreCompleto', 'Nombre'),
    col.texto<Cliente>('identificacion', 'Identificacion'),
    col.texto<Cliente>('telefono', 'Telefono'),
    col.fecha<Cliente>('fechaNacimiento', 'Nacimiento'),
  ],

  campos: [
    { name: 'nombreCompleto', label: 'Nombre completo', tipo: 'texto', requerido: true, colSpan: 2, autoFocus: true },
    { name: 'identificacion', label: 'Identificacion', tipo: 'texto', requerido: true },
    { name: 'telefono', label: 'Telefono', tipo: 'telefono' },
    { name: 'fechaNacimiento', label: 'Fecha de nacimiento', tipo: 'fecha' },
    { name: 'email', label: 'Email', tipo: 'email', colSpan: 2 },
  ],
  schema: clienteSchema,
  valoresPorDefecto: { nombreCompleto: '', identificacion: '', telefono: undefined, fechaNacimiento: undefined, email: undefined },
  aFormulario: (r) => ({
    nombreCompleto: r.nombreCompleto,
    identificacion: r.identificacion,
    telefono: r.telefono ?? undefined,
    // La Api puede mandar la fecha con hora (DATE -> "2020-01-01T00:00:00"); <input type=date> solo acepta 'yyyy-MM-dd'.
    fechaNacimiento: r.fechaNacimiento ? r.fechaNacimiento.slice(0, 10) : undefined,
    email: r.email ?? undefined,
  }),

  textoEliminar: (r) => `Se eliminara el cliente "${r.nombreCompleto}". Esta accion no se puede deshacer.`,
}

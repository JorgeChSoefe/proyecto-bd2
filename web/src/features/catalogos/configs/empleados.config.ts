import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Empleado } from '@/types/api'
import { zEmailOpc, zTextoOpc, zTextoReq } from '@/lib/validation'

const empleadoSchema = z.object({
  nombreCompleto: zTextoReq(255),
  cargo: zTextoOpc(255),
  email: zEmailOpc,
})

export type EmpleadoForm = z.infer<typeof empleadoSchema>

export const empleadosConfig: CrudConfig<Empleado, EmpleadoForm> = {
  recurso: 'empleados',
  endpoint: '/empleados',
  modulo: 'empleados',
  titulo: 'Empleados',
  tituloSingular: 'Empleado',
  getId: (r) => r.idEmpleado,

  columnas: [
    col.texto<Empleado>('nombreCompleto', 'Nombre'),
    col.texto<Empleado>('cargo', 'Cargo'),
    col.texto<Empleado>('email', 'Email'),
  ],

  campos: [
    { name: 'nombreCompleto', label: 'Nombre completo', tipo: 'texto', requerido: true, colSpan: 2, autoFocus: true },
    { name: 'cargo', label: 'Cargo', tipo: 'texto' },
    { name: 'email', label: 'Email', tipo: 'email' },
  ],
  schema: empleadoSchema,
  valoresPorDefecto: { nombreCompleto: '', cargo: undefined, email: undefined },
  aFormulario: (r) => ({ nombreCompleto: r.nombreCompleto, cargo: r.cargo ?? undefined, email: r.email ?? undefined }),

  textoEliminar: (r) => `Se eliminara el empleado "${r.nombreCompleto}". Si esta vinculado a un usuario, revisa esa cuenta primero.`,
}

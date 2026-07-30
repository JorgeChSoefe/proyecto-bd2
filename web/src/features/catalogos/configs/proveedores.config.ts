import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { Proveedor } from '@/types/api'
import { zEmailOpc, zTextoOpc, zTextoReq } from '@/lib/validation'

const proveedorSchema = z.object({
  nombreEmpresa: zTextoReq(255),
  contactoNombre: zTextoOpc(255),
  telefono: zTextoOpc(255),
  email: zEmailOpc,
})

export type ProveedorForm = z.infer<typeof proveedorSchema>

export const proveedoresConfig: CrudConfig<Proveedor, ProveedorForm> = {
  recurso: 'proveedores',
  endpoint: '/proveedores',
  modulo: 'proveedores',
  titulo: 'Proveedores',
  tituloSingular: 'Proveedor',
  getId: (r) => r.idProveedor,

  columnas: [
    col.texto<Proveedor>('nombreEmpresa', 'Empresa'),
    col.texto<Proveedor>('contactoNombre', 'Contacto'),
    col.texto<Proveedor>('telefono', 'Telefono'),
    col.texto<Proveedor>('email', 'Email'),
  ],

  campos: [
    { name: 'nombreEmpresa', label: 'Empresa', tipo: 'texto', requerido: true, colSpan: 2, autoFocus: true },
    { name: 'contactoNombre', label: 'Contacto', tipo: 'texto' },
    { name: 'telefono', label: 'Telefono', tipo: 'telefono' },
    { name: 'email', label: 'Email', tipo: 'email', colSpan: 2 },
  ],
  schema: proveedorSchema,
  valoresPorDefecto: { nombreEmpresa: '', contactoNombre: undefined, telefono: undefined, email: undefined },
  aFormulario: (r) => ({
    nombreEmpresa: r.nombreEmpresa,
    contactoNombre: r.contactoNombre ?? undefined,
    telefono: r.telefono ?? undefined,
    email: r.email ?? undefined,
  }),

  textoEliminar: (r) => `Se eliminara el proveedor "${r.nombreEmpresa}". Esta accion no se puede deshacer.`,
}

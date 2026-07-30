import { z } from 'zod'
import { col } from '@/components/crud/columnas'
import type { CrudConfig } from '@/components/crud/crud-config'
import type { UsuarioResponse } from '@/types/api'
import { zEmailOpc, zId, zIdOpc, zTextoReq } from '@/lib/validation'

// nombreUsuario/password solo viajan en el POST (CrearUsuarioRequest); el PUT
// (UsuarioUpdateRequest) es exactamente {email,idRol,idEmpleado} -- ver
// UsuariosController.cs. Se comparte un solo TForm (requisito del motor
// generico: createCrudApi<TRow,TForm> usa un unico tipo de body) y se ocultan
// nombreUsuario/password en modo edicion via soloEnCrear; el PUT los manda
// igual mezclados en el body, pero System.Text.Json ignora propiedades JSON
// que el record de destino no declara, asi que no rompe nada del lado del servidor.
const usuarioSchemaBase = {
  nombreUsuario: zTextoReq(255),
  password: z.string(), // sin minimo aqui -- en edicion el campo esta oculto y vacio, ver schemaEditar
  email: zEmailOpc,
  idRol: zId,
  idEmpleado: zIdOpc,
}

const usuarioSchemaCrear = z.object({ ...usuarioSchemaBase, password: z.string().min(8, 'Minimo 8 caracteres') })
const usuarioSchemaEditar = z.object(usuarioSchemaBase)

export type UsuarioForm = z.infer<typeof usuarioSchemaCrear>

export const usuariosConfig: CrudConfig<UsuarioResponse, UsuarioForm> = {
  recurso: 'usuarios',
  endpoint: '/usuarios',
  modulo: 'usuarios',
  titulo: 'Usuarios',
  tituloSingular: 'Usuario',
  getId: (r) => r.idUsuario,

  columnas: [
    col.texto<UsuarioResponse>('nombreUsuario', 'Usuario'),
    col.texto<UsuarioResponse>('email', 'Email'),
    col.texto<UsuarioResponse>('nombreRol', 'Rol'),
    col.bool<UsuarioResponse>('activo', 'Estado', ['Activo', 'Inactivo']),
  ],

  campos: [
    { name: 'nombreUsuario', label: 'Nombre de usuario', tipo: 'texto', requerido: true, autoFocus: true, soloEnCrear: true },
    { name: 'password', label: 'Password', tipo: 'password', requerido: true, ayuda: 'Minimo 8 caracteres.', soloEnCrear: true },
    { name: 'email', label: 'Email', tipo: 'email', colSpan: 2 },
    { name: 'idRol', label: 'Rol', tipo: 'lookup', requerido: true, lookup: { recurso: 'roles', endpoint: '/roles', campoId: 'idRol', campoEtiqueta: 'nombreRol' } },
    {
      name: 'idEmpleado',
      label: 'Empleado',
      tipo: 'lookup',
      ayuda: 'Opcional: vincula la cuenta a un registro de empleado.',
      lookup: { recurso: 'empleados', endpoint: '/empleados', campoId: 'idEmpleado', campoEtiqueta: 'nombreCompleto', campoSecundario: 'cargo' },
    },
  ],
  schema: usuarioSchemaCrear,
  schemaCrear: usuarioSchemaCrear,
  schemaEditar: usuarioSchemaEditar,
  valoresPorDefecto: { nombreUsuario: '', password: '', email: undefined, idRol: undefined as unknown as number, idEmpleado: undefined },
  aFormulario: (r) => ({
    nombreUsuario: r.nombreUsuario,
    password: '',
    email: r.email ?? undefined,
    idRol: r.idRol,
    idEmpleado: r.idEmpleado ?? undefined,
  }),

  // El endpoint DELETE en realidad desactiva (activo=0); no existe un
  // endpoint de reactivacion todavia, asi que el texto no promete deshacerlo.
  etiquetaEliminar: 'Desactivar',
  textoEliminar: (r) => `Se desactivara el usuario "${r.nombreUsuario}" y no podra iniciar sesion. No hay forma de reactivarlo desde este panel.`,
}

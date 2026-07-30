import type { LucideIcon } from 'lucide-react'
import {
  BellRing,
  Boxes,
  CalendarClock,
  FileText,
  FlaskConical,
  KeyRound,
  LayoutDashboard,
  Package,
  PillBottle,
  ScrollText,
  ShieldCheck,
  ShoppingCart,
  Truck,
  Users,
  UsersRound,
} from 'lucide-react'
import type { Permiso } from '@/lib/auth/permissions'

export interface NavItem {
  titulo: string
  to: string
  icono: LucideIcon
  perm: Permiso | Permiso[]
}

export interface NavGrupo {
  titulo: string
  items: NavItem[]
}

export const NAV: NavGrupo[] = [
  {
    titulo: 'Operacion',
    items: [
      { titulo: 'Panel', to: '/', icono: LayoutDashboard, perm: ['ventas:listar', 'inventario:consultar'] },
      { titulo: 'Ventas', to: '/ventas', icono: ShoppingCart, perm: 'ventas:listar' },
      { titulo: 'Compras', to: '/compras', icono: Truck, perm: 'compras:listar' },
      { titulo: 'Recetas', to: '/recetas', icono: FileText, perm: 'recetas:listar' },
    ],
  },
  {
    titulo: 'Inventario',
    items: [
      { titulo: 'Stock', to: '/inventario/stock', icono: Boxes, perm: 'inventario:consultar' },
      { titulo: 'Por vencer', to: '/inventario/por-vencer', icono: CalendarClock, perm: 'inventario:consultar' },
      { titulo: 'Kardex', to: '/inventario/kardex', icono: ScrollText, perm: 'inventario:consultar' },
      { titulo: 'Alertas', to: '/inventario/alertas', icono: BellRing, perm: 'inventario:consultar' },
    ],
  },
  {
    titulo: 'Catalogos',
    items: [
      { titulo: 'Productos', to: '/productos', icono: Package, perm: 'productos:listar' },
      { titulo: 'Clientes', to: '/clientes', icono: UsersRound, perm: 'clientes:listar' },
      { titulo: 'Categorias', to: '/categorias', icono: PillBottle, perm: 'categorias:listar' },
      { titulo: 'Proveedores', to: '/proveedores', icono: Truck, perm: 'proveedores:listar' },
      { titulo: 'Laboratorios', to: '/laboratorios', icono: FlaskConical, perm: 'laboratorios:listar' },
      { titulo: 'Principios activos', to: '/principios-activos', icono: FlaskConical, perm: 'principios_activos:listar' },
      { titulo: 'Presentaciones', to: '/presentaciones', icono: Package, perm: 'presentaciones:listar' },
    ],
  },
  {
    titulo: 'Administracion',
    items: [
      { titulo: 'Usuarios', to: '/usuarios', icono: Users, perm: 'usuarios:listar' },
      { titulo: 'Roles', to: '/roles', icono: ShieldCheck, perm: 'roles:listar' },
      { titulo: 'Permisos', to: '/permisos', icono: KeyRound, perm: 'permisos:listar' },
      { titulo: 'Empleados', to: '/empleados', icono: UsersRound, perm: 'empleados:listar' },
    ],
  },
]

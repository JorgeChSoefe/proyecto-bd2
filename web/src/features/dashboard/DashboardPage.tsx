import { AlertTriangle, BellRing, FileText, Package, ShoppingCart, Truck, UsersRound } from 'lucide-react'
import { PageHeader } from '@/components/layout/PageHeader'
import { apiFetch, buildQuery } from '@/lib/api/client'
import { useAuth } from '@/lib/auth/auth-context'
import type { Paginado } from '@/types/pagination'
import { TarjetaConteo } from './components/TarjetaConteo'

const total = (endpoint: string, params: Record<string, unknown> = {}) => () =>
  apiFetch<Paginado<unknown>>(`${endpoint}${buildQuery({ pagina: 1, tamano: 1, ...params })}`).then((r) => r.total)

/** Solo conteos -- no hay endpoint de agregados para montos sumados (ver Fase 0/9 del plan). */
export function DashboardPage() {
  const { sesion } = useAuth()

  return (
    <div>
      <PageHeader titulo="Panel" descripcion={`Hola, ${sesion?.nombreUsuario ?? ''}.`} />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
        <TarjetaConteo titulo="Ventas" icono={ShoppingCart} permiso="ventas:listar" ruta="/ventas" consulta={total('/ventas')} />
        <TarjetaConteo titulo="Compras pendientes" icono={Truck} permiso="compras:listar" ruta="/compras?estado=pendiente" consulta={total('/compras', { estado: 'pendiente' })} />
        <TarjetaConteo titulo="Recetas pendientes" icono={FileText} permiso="recetas:listar" ruta="/recetas" consulta={total('/recetas/pendientes')} />
        <TarjetaConteo
          titulo="Alertas activas"
          icono={BellRing}
          permiso="inventario:consultar"
          ruta="/inventario/alertas"
          consulta={total('/inventario/alertas')}
        />
        <TarjetaConteo
          titulo="Productos bajo stock minimo"
          icono={AlertTriangle}
          permiso="inventario:consultar"
          ruta="/inventario/stock?soloBajoMinimo=true"
          consulta={total('/inventario/stock', { soloBajoMinimo: true })}
        />
        <TarjetaConteo titulo="Productos" icono={Package} permiso="productos:listar" ruta="/productos" consulta={total('/productos')} />
        <TarjetaConteo titulo="Clientes" icono={UsersRound} permiso="clientes:listar" ruta="/clientes" consulta={total('/clientes')} />
      </div>
    </div>
  )
}

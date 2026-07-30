import { createBrowserRouter } from 'react-router'
import { AppLayout } from '@/components/layout/AppLayout'
import { CrudPage } from '@/components/crud/CrudPage'
import { ErrorBoundary } from '@/components/feedback/ErrorBoundary'
import { NotFound } from '@/components/feedback/NotFound'
import { LoginPage } from '@/features/auth/LoginPage'
import { RutaProtegida } from '@/features/auth/RutaProtegida'
import { CATALOGOS } from '@/features/catalogos/registry'
import { clientesConfig } from '@/features/clientes/clientes.config'
import { CompraDetallePage } from '@/features/compras/CompraDetallePage'
import { CompraNuevaPage } from '@/features/compras/CompraNuevaPage'
import { CompraRecibirPage } from '@/features/compras/CompraRecibirPage'
import { comprasConfig } from '@/features/compras/compras.config'
import { DashboardPage } from '@/features/dashboard/DashboardPage'
import { alertasConfig } from '@/features/inventario/alertas.config'
import { KardexPage } from '@/features/inventario/KardexPage'
import { PorVencerPage } from '@/features/inventario/PorVencerPage'
import { stockConfig } from '@/features/inventario/stock.config'
import { ProductoDetallePage } from '@/features/productos/ProductoDetallePage'
import { productosConfig } from '@/features/productos/productos.config'
import { RecetaDetallePage } from '@/features/recetas/RecetaDetallePage'
import { RecetaNuevaPage } from '@/features/recetas/RecetaNuevaPage'
import { recetasConfig } from '@/features/recetas/recetas.config'
import { usuariosConfig } from '@/features/usuarios/usuarios.config'
import { VentaDetallePage } from '@/features/ventas/VentaDetallePage'
import { VentaNuevaPage } from '@/features/ventas/VentaNuevaPage'
import { ventasConfig } from '@/features/ventas/ventas.config'

// Fases 0-8 del plan completas -- falta el pulido de la Fase 9.
export const router = createBrowserRouter([
  { path: '/login', element: <LoginPage />, errorElement: <ErrorBoundary /> },
  {
    element: <RutaProtegida />,
    errorElement: <ErrorBoundary />,
    children: [
      {
        element: <AppLayout />,
        children: [
          { index: true, element: <DashboardPage /> },
          { path: 'usuarios', element: <CrudPage config={usuariosConfig} /> },
          { path: 'clientes', element: <CrudPage config={clientesConfig} /> },
          { path: 'productos', element: <CrudPage config={productosConfig} /> },
          { path: 'productos/:id', element: <ProductoDetallePage /> },
          { path: 'inventario/stock', element: <CrudPage config={stockConfig} /> },
          { path: 'inventario/por-vencer', element: <PorVencerPage /> },
          { path: 'inventario/kardex', element: <KardexPage /> },
          { path: 'inventario/kardex/:idProducto', element: <KardexPage /> },
          { path: 'inventario/alertas', element: <CrudPage config={alertasConfig} /> },
          { path: 'recetas', element: <CrudPage config={recetasConfig} /> },
          { path: 'recetas/nueva', element: <RecetaNuevaPage /> },
          { path: 'recetas/:id', element: <RecetaDetallePage /> },
          { path: 'ventas', element: <CrudPage config={ventasConfig} /> },
          { path: 'ventas/nueva', element: <VentaNuevaPage /> },
          { path: 'ventas/:id', element: <VentaDetallePage /> },
          { path: 'compras', element: <CrudPage config={comprasConfig} /> },
          { path: 'compras/nueva', element: <CompraNuevaPage /> },
          { path: 'compras/:id/recibir', element: <CompraRecibirPage /> },
          { path: 'compras/:id', element: <CompraDetallePage /> },
          ...CATALOGOS.map((config) => ({ path: config.recurso, element: <CrudPage config={config} /> })),
        ],
      },
    ],
  },
  { path: '*', element: <NotFound />, errorElement: <ErrorBoundary /> },
])

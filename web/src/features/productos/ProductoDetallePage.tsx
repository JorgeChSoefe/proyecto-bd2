import { useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { Pencil } from 'lucide-react'
import { Navigate, useParams, useSearchParams } from 'react-router'
import { CrudFormDialog } from '@/components/crud/CrudFormDialog'
import { PageHeader } from '@/components/layout/PageHeader'
import { SinPermiso } from '@/components/feedback/SinPermiso'
import { Button } from '@/components/ui/button'
import { Skeleton } from '@/components/ui/skeleton'
import { Tabs, TabsContent, TabsList, TabsTrigger } from '@/components/ui/tabs'
import { apiFetch } from '@/lib/api/client'
import { createCrudApi } from '@/lib/api/crud-factory'
import { invalidarCatalogo } from '@/lib/api/invalidaciones'
import { qk } from '@/lib/api/query-keys'
import { useCan } from '@/lib/auth/use-can'
import type { ProductoDetalleDto } from '@/types/api'
import { productosConfig, type ProductoForm } from './productos.config'
import { FichaClinicaTab } from './components/FichaClinicaTab'
import { PrincipiosActivosTab } from './components/PrincipiosActivosTab'
import { ProductoGeneralTab } from './components/ProductoGeneralTab'

const TABS = ['general', 'ficha', 'principios'] as const

/** /productos/:id -- General | Ficha clinica | Principios activos, con la pestana activa en la URL (?tab=). */
export function ProductoDetallePage() {
  const { id } = useParams()
  const idProducto = Number(id)
  const [searchParams, setSearchParams] = useSearchParams()
  const { can } = useCan()
  const qc = useQueryClient()
  const [editOpen, setEditOpen] = useState(false)

  const tabParam = searchParams.get('tab')
  const tab = (TABS as readonly string[]).includes(tabParam ?? '') ? (tabParam as (typeof TABS)[number]) : 'general'

  const { data, isLoading } = useQuery({
    queryKey: qk.productos.detalle(idProducto),
    queryFn: () => apiFetch<ProductoDetalleDto>(`/productos/${idProducto}`),
    enabled: can('productos:ver') && Number.isFinite(idProducto),
  })

  const api = createCrudApi<never, ProductoForm>('/productos')
  const actualizar = useMutation({
    mutationFn: api.actualizar,
    onSuccess: () => {
      invalidarCatalogo(qc, 'productos')
      void qc.invalidateQueries({ queryKey: qk.productos.detalle(idProducto) })
    },
  })

  if (!Number.isFinite(idProducto)) return <Navigate to="/productos" replace />
  if (!can('productos:ver')) return <SinPermiso />

  if (isLoading || !data) {
    return (
      <div className="space-y-4">
        <Skeleton className="h-8 w-64" />
        <Skeleton className="h-64 w-full" />
      </div>
    )
  }

  return (
    <div>
      <PageHeader
        titulo={data.producto.nombre}
        descripcion={data.producto.codigoSku ?? undefined}
        acciones={
          can('productos:editar') && (
            <Button variant="outline" onClick={() => setEditOpen(true)}>
              <Pencil className="size-4" />
              Editar producto
            </Button>
          )
        }
      />

      <Tabs
        value={tab}
        onValueChange={(v) =>
          setSearchParams(
            (prev) => {
              const next = new URLSearchParams(prev)
              next.set('tab', v)
              return next
            },
            { replace: true },
          )
        }
      >
        <TabsList>
          <TabsTrigger value="general">General</TabsTrigger>
          <TabsTrigger value="ficha">Ficha clinica</TabsTrigger>
          <TabsTrigger value="principios">Principios activos</TabsTrigger>
        </TabsList>
        <TabsContent value="general" className="mt-4">
          <ProductoGeneralTab producto={data.producto} />
        </TabsContent>
        <TabsContent value="ficha" className="mt-4">
          <FichaClinicaTab idProducto={idProducto} medicamento={data.medicamento} />
        </TabsContent>
        <TabsContent value="principios" className="mt-4">
          <PrincipiosActivosTab idProducto={idProducto} medicamento={data.medicamento} principios={data.principiosActivos} />
        </TabsContent>
      </Tabs>

      <CrudFormDialog
        config={productosConfig}
        open={editOpen}
        onOpenChange={setEditOpen}
        filaEditar={data.producto}
        onCrear={() => Promise.reject(new Error('No aplica: esta pagina solo edita.'))}
        onActualizar={(args) => actualizar.mutateAsync(args)}
        enviando={actualizar.isPending}
      />
    </div>
  )
}

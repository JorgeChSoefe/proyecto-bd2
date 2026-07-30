import { QueryCache, QueryClient, QueryClientProvider } from '@tanstack/react-query'
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { RouterProvider } from 'react-router'
import { Toaster, toast } from 'sonner'
import { ApiError } from '@/lib/api/client'
import { AuthProvider } from '@/lib/auth/auth-context'
import { router } from './router'
import './index.css'

const queryClient = new QueryClient({
  queryCache: new QueryCache({
    onError: (error) => {
      // 401 ya lo maneja alManejarNoAutorizado (dispara el ReauthDialog);
      // aca solo se avisan errores de servidor genuinos.
      if (error instanceof ApiError && error.status >= 500) {
        toast.error('Error del servidor. Intenta de nuevo en un momento.')
      }
    },
  }),
  defaultOptions: {
    queries: {
      staleTime: 30_000,
      refetchOnWindowFocus: false,
      retry: (failureCount, error) => !(error instanceof ApiError && error.status < 500) && failureCount < 2,
    },
    mutations: {
      // Nunca reintentar una mutacion sola: un POST de venta/compra
      // reintentado automaticamente es una venta/compra duplicada moviendo
      // stock real.
      retry: false,
    },
  },
})

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <RouterProvider router={router} />
        <Toaster richColors position="top-right" />
      </AuthProvider>
    </QueryClientProvider>
  </StrictMode>,
)

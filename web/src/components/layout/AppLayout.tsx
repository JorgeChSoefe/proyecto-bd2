import { useState } from 'react'
import { Outlet } from 'react-router'
import { Sheet, SheetContent, SheetTitle } from '@/components/ui/sheet'
import { ReauthDialog } from '@/features/auth/ReauthDialog'
import { Sidebar } from './Sidebar'
import { Topbar } from './Topbar'

export function AppLayout() {
  const [menuMovilAbierto, setMenuMovilAbierto] = useState(false)

  return (
    <div className="grid h-svh grid-cols-1 md:grid-cols-[16rem_1fr]">
      <div className="hidden border-r md:block">
        <Sidebar />
      </div>

      <Sheet open={menuMovilAbierto} onOpenChange={setMenuMovilAbierto}>
        <SheetContent side="left" className="w-64 p-0">
          <SheetTitle className="sr-only">Menu</SheetTitle>
          <Sidebar />
        </SheetContent>
      </Sheet>

      <div className="flex min-w-0 flex-col">
        <Topbar onAbrirMenu={() => setMenuMovilAbierto(true)} />
        <main className="flex-1 overflow-auto p-6">
          <Outlet />
        </main>
      </div>

      <ReauthDialog />
    </div>
  )
}

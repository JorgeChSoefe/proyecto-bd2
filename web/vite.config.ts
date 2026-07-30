import path from 'path'
import tailwindcss from '@tailwindcss/vite'
import react from '@vitejs/plugin-react'
import { defineConfig } from 'vite'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react(), tailwindcss()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    proxy: {
      // La Api no tiene CORS configurado a proposito (single-origin es mas
      // simple y seguro) -- este proxy evita necesitarlo en dev. Apunta al
      // perfil "http" de launchSettings.json (puerto 5086).
      '/api': {
        target: 'http://localhost:5086',
        changeOrigin: true,
      },
    },
  },
})

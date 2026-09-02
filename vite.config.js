import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vitejs.dev/config/
export default defineConfig({
  plugins: [react()],
  // Prefer TypeScript sources so any leftover legacy .jsx/.js files never shadow them.
  resolve: {
    extensions: ['.tsx', '.ts', '.jsx', '.js', '.mjs', '.json'],
  },
  server: {
    port: 5173,
    open: true,
  },
})

import { defineConfig } from 'vite'
import react from '@vitejs/react-refresh' // или @vitejs/plugin-react
import { nodePolyfills } from 'vite-plugin-node-polyfills'

export default defineConfig({
  plugins: [
    react(),
    nodePolyfills(), // Это добавит EventEmitter, Buffer и прочее
  ],
})

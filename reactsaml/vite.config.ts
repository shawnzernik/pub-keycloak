import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";

export default defineConfig({
  plugins: [react()],
  build: {
    outDir: "dist",         // Ensure built files go to 'dist'
    emptyOutDir: true,      // Clear 'dist' before building
    sourcemap: true,        // Generate source maps for debugging
  },
  define: {
    "import.meta.env.VITE_API_BASE_URL": JSON.stringify(process.env.VITE_API_BASE_URL || "http://localhost:5000")
  }
});
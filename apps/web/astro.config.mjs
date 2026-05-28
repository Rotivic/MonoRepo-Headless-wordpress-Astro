import { defineConfig } from 'astro/config';

export default defineConfig({
  server: {
    host: true,
    port: 4321,
  },
  vite: {
    server: {
      watch: {
        usePolling: true,
        interval: 300,
      },
    },
  },
});

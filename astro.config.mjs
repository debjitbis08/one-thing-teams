// @ts-check
import { defineConfig } from 'astro/config';

import node from '@astrojs/node';

// https://astro.build/config
export default defineConfig({
  vite: {
    // Don’t pre-optimize these for the browser
    optimizeDeps: {
      exclude: [
        '@node-rs/argon2',
        '@node-rs/argon2-wasm32-wasi',
      ],
    },
    // For SSR, use Node’s resolver instead of bundling native binaries
    ssr: {
      external: ['@node-rs/argon2'],
    },
  },

  adapter: node({
    mode: 'standalone',
  }),
});
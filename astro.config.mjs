// @ts-check
import { defineConfig } from 'astro/config';
import node from '@astrojs/node';
import solidJs from '@astrojs/solid-js';
import alpinejs from '@astrojs/alpinejs';
import icon from 'astro-icon';
import tailwindcss from '@tailwindcss/vite';

// https://astro.build/config
export default defineConfig({
  vite: {
    plugins: [tailwindcss()],
    resolve: {
      alias: {
        // solid-icons@1.2.0 bug: subpath .js files import '../lib/index.jsx'
        // (raw JSX) instead of the pre-compiled '../lib/index.js'. This alias
        // redirects to the compiled version so Vite doesn't need to transform it.
        'solid-icons/lib/index.jsx': 'solid-icons/lib/index.js',
      },
    },
    optimizeDeps: {
      exclude: [
        '@node-rs/argon2',
        '@node-rs/argon2-wasm32-wasi',
      ],
    },
    ssr: {
      external: ['@node-rs/argon2'],
    },
  },

  integrations: [
    solidJs(),
    alpinejs(),
    icon({
      include: {
        lucide: ['*'],
      },
    }),
  ],

  adapter: node({
    mode: 'standalone',
  }),
});

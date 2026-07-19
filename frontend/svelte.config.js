import adapter from '@sveltejs/adapter-static';
import { staticDemoRoutes } from './demo-routes.mjs';

/** @type {import('@sveltejs/kit').Config} */
const config = {
  compilerOptions: {
    // Force runes mode for the project, except for libraries. Can be removed in svelte 6.
    runes: ({ filename }) => (filename.split(/[/\\]/).includes('node_modules') ? undefined : true),
  },
  kit: {
    // Known demo routes are emitted as real HTML documents so direct links on
    // GitHub Pages return 200. The fallback covers friendly unknown-ID views.
    adapter: adapter({ fallback: '404.html' }),
    prerender: {
      entries: staticDemoRoutes,
    },
  },
};

export default config;

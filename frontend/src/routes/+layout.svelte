<script lang="ts">
  import '../app.css';
  import '@fontsource/inter/latin-400.css';
  import '@fontsource/inter/latin-500.css';
  import '@fontsource/inter/latin-600.css';
  import '@fontsource/inter/latin-700.css';
  import '@fontsource/inter/latin-800.css';
  import '@fontsource/caveat/latin-400.css';
  import '@fontsource/caveat/latin-600.css';
  import '@fontsource/caveat/latin-700.css';
  import '@fontsource/material-symbols-outlined/400.css';
  import ToastHost from '$lib/components/ui/ToastHost.svelte';
  import DemoBar from '$lib/components/demo/DemoBar.svelte';

  let { children } = $props();
</script>

<DemoBar />

{@render children()}

<ToastHost />

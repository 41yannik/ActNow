<script lang="ts">
  // Two-column auth shell: brand panel + form panel.
  import type { Snippet } from 'svelte';

  interface Props {
    title: string;
    subtitle?: string;
    children: Snippet;
    footer?: Snippet;
  }
  const { title, subtitle, children, footer }: Props = $props();
</script>

<div class="grid min-h-screen grid-cols-1 lg:grid-cols-2">
  <aside
    class="hidden flex-col justify-between bg-gradient-to-br from-primary to-tertiary p-xl text-on-primary lg:flex"
  >
    <a href="/" class="font-h2 text-h2">ActNow</a>
    <div>
      <h1 class="font-h1 text-h1 mb-md">Gemeinsam etwas bewegen.</h1>
      <p class="font-body-md text-body-md max-w-md opacity-90">
        Verbinde dich mit Vereinen und Initiativen in deiner Nähe – oder finde Helfer:innen für dein
        Projekt.
      </p>
    </div>
    <p class="text-label-md font-label-md opacity-70">© ActNow</p>
  </aside>
  <main class="flex items-center justify-center p-md sm:p-xl">
    <div class="w-full max-w-md">
      <h2 class="font-h2 text-h2 mb-xs text-on-surface">{title}</h2>
      {#if subtitle}
        <p class="font-body-md text-body-md mb-lg text-on-surface-variant">{subtitle}</p>
      {/if}
      {@render children()}
      {#if footer}
        <div class="mt-lg text-center text-on-surface-variant">{@render footer()}</div>
      {/if}
    </div>
  </main>
</div>

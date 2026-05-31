<script lang="ts">
  import type { Snippet } from 'svelte';
  // Slot-based shell. Use one of `top` / `side` for the chrome.
  interface Props {
    top?: Snippet;
    side?: Snippet;
    bottom?: Snippet;
    footer?: Snippet;
    main: Snippet;
    /** Set true when using `side` so main content gets left padding on md+. */
    docked?: boolean;
  }
  let { top, side, bottom, footer, main, docked = false }: Props = $props();
</script>

<div class="min-h-screen flex flex-col">
  {#if top}{@render top()}{/if}
  <div class="flex flex-1">
    {#if side}{@render side()}{/if}
    <main class="min-w-0 flex-1 {docked ? 'md:ml-64' : ''} pb-[80px] md:pb-0">
      {@render main()}
    </main>
  </div>
  {#if bottom}{@render bottom()}{/if}
  {#if footer}{@render footer()}{/if}
</div>

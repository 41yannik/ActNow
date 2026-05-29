<script lang="ts">
  import { toasts } from '$lib/stores/toasts.svelte';
  import Toast from './Toast.svelte';
</script>

<div
  class="pointer-events-none fixed inset-x-0 top-4 z-[100] flex flex-col items-center gap-xs px-sm sm:top-6"
  aria-live="polite"
>
  {#each toasts.items as t (t.id)}
    <div class="w-full max-w-sm">
      <Toast toast={t} />
    </div>
  {/each}
</div>

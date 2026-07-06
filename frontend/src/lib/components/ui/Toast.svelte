<script lang="ts">
  import Icon from './Icon.svelte';
  import IconButton from './IconButton.svelte';
  import { toasts, type Toast as ToastItem } from '$lib/stores/toasts.svelte';

  interface Props {
    toast: ToastItem;
  }
  const { toast }: Props = $props();

  const tones = {
    info: { wrap: 'bg-secondary-container text-on-secondary-container', icon: 'info' },
    success: { wrap: 'bg-tertiary-fixed text-on-tertiary-fixed', icon: 'check_circle' },
    warning: { wrap: 'bg-secondary-container text-on-secondary-container', icon: 'warning' },
    error: { wrap: 'bg-error-container text-on-error-container', icon: 'error' },
  } as const;

  const tone = $derived(tones[toast.tone]);
</script>

<div
  class="pointer-events-auto flex w-full items-start gap-sm rounded-lg p-sm shadow-lg {tone.wrap}"
  role="status"
  aria-live="polite"
>
  <Icon name={tone.icon} size={20} class="mt-0.5 shrink-0" />
  <div class="min-w-0 flex-1">
    {#if toast.title}
      <p class="font-label-md text-label-md">{toast.title}</p>
    {/if}
    <p class="font-body-md text-body-md">{toast.message}</p>
  </div>
  <IconButton icon="close" label="Schließen" size="sm" onclick={() => toasts.dismiss(toast.id)} />
</div>

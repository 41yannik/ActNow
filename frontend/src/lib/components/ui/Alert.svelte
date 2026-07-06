<script lang="ts">
  import type { Snippet } from 'svelte';
  import Icon from './Icon.svelte';

  type Tone = 'info' | 'success' | 'warning' | 'error';
  interface Props {
    tone?: Tone;
    title?: string;
    class?: string;
    children?: Snippet;
  }
  let { tone = 'info', title, class: klass = '', children }: Props = $props();

  const tones: Record<Tone, { wrap: string; icon: string }> = {
    info: { wrap: 'bg-secondary-container text-on-secondary-container', icon: 'info' },
    success: { wrap: 'bg-tertiary-fixed text-on-tertiary-fixed', icon: 'check_circle' },
    warning: { wrap: 'bg-secondary-container text-on-secondary-container', icon: 'warning' },
    error: { wrap: 'bg-error-container text-on-error-container', icon: 'error' },
  };
</script>

<div class="flex items-start gap-sm rounded-lg p-md {tones[tone].wrap} {klass}" role="alert">
  <Icon name={tones[tone].icon} size={22} class="mt-0.5 shrink-0" />
  <div class="flex-1">
    {#if title}<p class="font-label-md text-label-md mb-1">{title}</p>{/if}
    {#if children}
      <div class="font-body-md text-body-md">{@render children()}</div>
    {/if}
  </div>
</div>

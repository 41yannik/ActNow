<script lang="ts">
  import Icon from './Icon.svelte';

  interface Props {
    value: number; // 0..5, supports halves
    count?: number | null;
    size?: number;
    showValue?: boolean;
    class?: string;
  }
  let {
    value,
    count = null,
    size = 16,
    showValue = true,
    class: klass = ''
  }: Props = $props();

  const stars = $derived(
    Array.from({ length: 5 }, (_, i) => {
      const v = value - i;
      if (v >= 1) return 'full';
      if (v >= 0.5) return 'half';
      return 'empty';
    }) as ('full' | 'half' | 'empty')[]
  );
</script>

<span
  class="inline-flex items-center gap-xs text-on-surface font-label-md text-label-md {klass}"
  aria-label={`Bewertung ${value.toFixed(1)} von 5${count != null ? `, ${count} Bewertungen` : ''}`}
>
  <span class="flex" aria-hidden="true">
    {#each stars as kind}
      {#if kind === 'full'}
        <Icon name="star" filled {size} class="text-primary" />
      {:else if kind === 'half'}
        <Icon name="star_half" filled {size} class="text-primary" />
      {:else}
        <Icon name="star" {size} class="text-outline-variant" />
      {/if}
    {/each}
  </span>
  {#if showValue}
    <span>{value.toFixed(1)}</span>
  {/if}
  {#if count != null}
    <span class="text-on-surface-variant font-body-md">({count})</span>
  {/if}
</span>

<script lang="ts">
  // Dashboard metric tile with optional trend indicator.
  import Icon from '$lib/components/ui/Icon.svelte';

  interface Props {
    icon?: string;
    label: string;
    value: string | number;
    trend?: number | null;
    trendLabel?: string | null;
    onclick?: () => void;
    class?: string;
  }
  const { icon, label, value, trend = null, trendLabel = null, onclick, class: klass = '' }: Props =
    $props();

  const trendUp = $derived(trend != null && trend > 0);
  const trendDown = $derived(trend != null && trend < 0);
</script>

<svelte:element
  this={onclick ? 'button' : 'div'}
  type={onclick ? 'button' : undefined}
  onclick={onclick}
  class="flex w-full flex-col gap-xs rounded-2xl bg-surface-container-low p-md text-left text-on-surface transition-colors {onclick ? 'hover:bg-surface-container' : ''} {klass}"
>
  <div class="flex items-center gap-sm">
    {#if icon}<Icon name={icon} size={20} class="text-primary" />{/if}
    <span class="text-label-md font-label-md text-on-surface-variant">{label}</span>
  </div>
  <span class="font-h2 text-h2">{value}</span>
  {#if trend != null}
    <span
      class="inline-flex items-center gap-1 text-[12px] {trendUp ? 'text-tertiary' : trendDown ? 'text-error' : 'text-on-surface-variant'}"
    >
      <Icon name={trendUp ? 'trending_up' : trendDown ? 'trending_down' : 'trending_flat'} size={14} />
      {trend > 0 ? '+' : ''}{trend}{trendLabel ? ` ${trendLabel}` : ''}
    </span>
  {/if}
</svelte:element>

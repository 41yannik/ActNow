<script lang="ts">
  import type { Snippet } from 'svelte';
  import Icon from './Icon.svelte';

  type Variant = 'filter' | 'selected' | 'input';
  interface Props {
    icon?: string;
    label?: string;
    variant?: Variant;
    onclick?: () => void;
    removable?: boolean;
    onremove?: () => void;
    class?: string;
    children?: Snippet;
  }
  let {
    icon,
    label,
    variant = 'filter',
    onclick,
    removable = false,
    onremove,
    class: klass = '',
    children
  }: Props = $props();

  const variants: Record<Variant, string> = {
    filter:
      'bg-surface-container-low text-on-surface-variant hover:bg-surface-container',
    selected:
      'bg-secondary-container text-on-secondary-container hover:bg-secondary-container/80',
    input: 'bg-surface-container text-on-surface'
  };

  const isButton = $derived(!!onclick);
</script>

<svelte:element
  this={isButton ? 'button' : 'span'}
  type={isButton ? 'button' : undefined}
  role={isButton ? 'button' : undefined}
  onclick={() => onclick?.()}
  class="
    inline-flex items-center gap-xs px-sm py-2 rounded-full transition-colors cursor-pointer
    font-label-md text-label-md
    {variants[variant]} {klass}
  "
>
  {#if icon}<Icon name={icon} size={18} />{/if}
  {#if children}
    {@render children()}
  {:else if label}
    <span>{label}</span>
  {/if}
  {#if removable}
    <button
      type="button"
      class="ml-1 -mr-1 rounded-full hover:bg-on-surface/10 p-0.5"
      aria-label="Entfernen"
      onclick={(e) => {
        e.stopPropagation();
        onremove?.();
      }}
    >
      <Icon name="close" size={14} />
    </button>
  {/if}
</svelte:element>

<script lang="ts" generics="T extends string | number">
  interface TabItem {
    value: T;
    label: string;
    icon?: string;
  }
  interface Props {
    items: TabItem[];
    value: T;
    onchange?: (value: T) => void;
    class?: string;
    /** 'segmented' style or 'underline'. */
    variant?: 'segmented' | 'underline';
  }
  import Icon from './Icon.svelte';

  let {
    items,
    value = $bindable(),
    onchange,
    class: klass = '',
    variant = 'segmented',
  }: Props = $props();

  function select(v: T) {
    value = v;
    onchange?.(v);
  }
</script>

{#if variant === 'segmented'}
  <div
    class="inline-flex rounded-full border border-outline-variant bg-surface-container-low p-1 {klass}"
    role="tablist"
  >
    {#each items as item}
      <button
        type="button"
        role="tab"
        aria-selected={value === item.value}
        class="inline-flex items-center gap-xs rounded-full px-sm py-1.5 font-label-md text-label-md transition-colors {value ===
        item.value
          ? 'bg-primary text-on-primary'
          : 'text-on-surface-variant hover:bg-surface-container'}"
        onclick={() => select(item.value)}
      >
        {#if item.icon}<Icon name={item.icon} size={16} />{/if}
        {item.label}
      </button>
    {/each}
  </div>
{:else}
  <div class="flex border-b border-outline-variant {klass}" role="tablist">
    {#each items as item}
      <button
        type="button"
        role="tab"
        aria-selected={value === item.value}
        class="inline-flex items-center gap-xs px-md py-sm font-label-md text-label-md transition-colors {value ===
        item.value
          ? 'border-b-2 border-primary text-primary'
          : 'text-on-surface-variant hover:text-on-surface'}"
        onclick={() => select(item.value)}
      >
        {#if item.icon}<Icon name={item.icon} size={18} />{/if}
        {item.label}
      </button>
    {/each}
  </div>
{/if}

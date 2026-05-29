<script lang="ts" generics="T extends string | number">
  import type { Snippet } from 'svelte';
  import Icon from '../ui/Icon.svelte';

  interface Option {
    value: T;
    label: string;
  }
  interface Props {
    label?: string;
    options?: Option[];
    value?: T | '';
    helper?: string;
    error?: string | null;
    placeholder?: string;
    id?: string;
    class?: string;
    children?: Snippet; // allow <option> children if no `options` provided
  }
  let {
    label,
    options,
    value = $bindable('' as T | ''),
    helper,
    error = null,
    placeholder,
    id,
    class: klass = '',
    children
  }: Props = $props();

  const sel = $derived(id ?? `sel-${Math.random().toString(36).slice(2, 9)}`);
</script>

<div class="w-full {klass}">
  {#if label}
    <label for={sel} class="block font-label-md text-label-md text-on-surface-variant mb-1">{label}</label>
  {/if}
  <div class="relative">
    <select
      id={sel}
      bind:value
      class="
        w-full bg-surface border rounded-lg pl-sm pr-10 py-sm text-on-surface appearance-none
        font-body-md text-body-md transition-shadow
        focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary
        {error ? 'border-error focus:ring-error focus:border-error' : 'border-outline-variant'}
      "
    >
      {#if placeholder}<option value="" disabled>{placeholder}</option>{/if}
      {#if options}
        {#each options as o}<option value={o.value}>{o.label}</option>{/each}
      {:else if children}
        {@render children()}
      {/if}
    </select>
    <span class="absolute right-sm top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none">
      <Icon name="expand_more" />
    </span>
  </div>
  {#if error}
    <p class="mt-1 text-[13px] text-error font-label-md">{error}</p>
  {:else if helper}
    <p class="mt-1 text-[13px] text-on-surface-variant">{helper}</p>
  {/if}
</div>

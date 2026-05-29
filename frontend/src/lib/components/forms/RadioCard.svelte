<script lang="ts">
  import type { Snippet } from 'svelte';
  import Icon from '../ui/Icon.svelte';
  // Boxed radio tile (role pick on register, location-type on newoffer).
  interface Props {
    label: string;
    description?: string;
    icon?: string;
    name: string;
    value: string;
    group?: string;
    class?: string;
    children?: Snippet;
  }
  let {
    label,
    description,
    icon,
    name,
    value,
    group = $bindable<string>(''),
    class: klass = '',
    children
  }: Props = $props();

  const selected = $derived(group === value);
</script>

<label
  class="
    relative flex items-start gap-3 p-md rounded-xl border cursor-pointer transition-all
    {selected
      ? 'bg-tertiary-fixed border-primary shadow-[0px_4px_20px_rgba(47,79,79,0.08)]'
      : 'bg-surface border-outline-variant hover:bg-surface-container-low'}
    {klass}
  "
>
  <input type="radio" {name} {value} bind:group class="sr-only" />
  {#if icon}
    <span
      class="
        shrink-0 w-10 h-10 rounded-lg flex items-center justify-center
        {selected ? 'bg-primary text-on-primary' : 'bg-surface-container text-on-surface-variant'}
      "
    >
      <Icon name={icon} size={22} />
    </span>
  {/if}
  <span class="flex-1">
    <span class="font-label-md text-label-md text-on-surface block">{label}</span>
    {#if description}
      <span class="font-body-md text-[13px] text-on-surface-variant block mt-0.5">{description}</span>
    {/if}
    {#if children}{@render children()}{/if}
  </span>
  <span
    class="
      shrink-0 mt-1 w-5 h-5 rounded-full border-2 flex items-center justify-center
      {selected ? 'border-primary' : 'border-outline'}
    "
    aria-hidden="true"
  >
    {#if selected}<span class="w-2.5 h-2.5 rounded-full bg-primary"></span>{/if}
  </span>
</label>

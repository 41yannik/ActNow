<script lang="ts">
  import type { Snippet } from 'svelte';
  // Boxed checkbox tile (requirements list pattern from newoffer.html).
  interface Props {
    label: string;
    description?: string;
    checked?: boolean;
    class?: string;
    children?: Snippet;
  }
  let {
    label,
    description,
    checked = $bindable(false),
    class: klass = '',
    children
  }: Props = $props();
</script>

<label
  class="flex items-start gap-3 p-sm bg-surface border border-outline-variant rounded-lg cursor-pointer
         hover:bg-surface-container transition-colors {klass}"
>
  <input
    type="checkbox"
    bind:checked
    class="rounded text-primary focus:ring-primary h-5 w-5 border-outline mt-0.5"
  />
  <span class="flex-1">
    <span class="font-body-md text-body-md text-on-surface block">{label}</span>
    {#if description}
      <span class="font-body-md text-[13px] text-on-surface-variant block">{description}</span>
    {/if}
    {#if children}{@render children()}{/if}
  </span>
</label>

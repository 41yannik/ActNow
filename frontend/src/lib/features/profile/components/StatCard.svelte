<script lang="ts">
  // Small key-figure tile.
  import Icon from '$lib/components/ui/Icon.svelte';

  interface Props {
    icon?: string;
    label: string;
    value: string | number;
    sublabel?: string | null;
    class?: string;
  }
  const { icon, label, value, sublabel = null, class: klass = '' }: Props = $props();
</script>

<div
  class="flex flex-col gap-1 rounded-2xl bg-surface-container-low p-md text-on-surface {klass}"
>
  {#if icon}
    <Icon name={icon} size={20} class="text-primary" />
  {/if}
  <span class="font-h3 text-h3">{value}</span>
  <span class="text-label-md font-label-md text-on-surface-variant">{label}</span>
  {#if sublabel}
    <span class="text-[12px] text-on-surface-variant">{sublabel}</span>
  {/if}
</div>

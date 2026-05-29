<script lang="ts">
  import Icon from './Icon.svelte';
  interface Props {
    label: string;
    removable?: boolean;
    onremove?: () => void;
    class?: string;
  }
  let { label, removable = false, onremove, class: klass = '' }: Props = $props();
</script>

<span
  class="inline-flex items-center gap-1 px-2.5 py-1 rounded-full
         bg-tertiary-fixed text-on-tertiary-fixed-variant
         font-label-md text-[12px] {klass}"
>
  {label}
  {#if removable}
    <button
      type="button"
      aria-label={`${label} entfernen`}
      class="rounded-full hover:bg-on-surface/10 p-0.5"
      onclick={onremove}
    >
      <Icon name="close" size={12} />
    </button>
  {/if}
</span>

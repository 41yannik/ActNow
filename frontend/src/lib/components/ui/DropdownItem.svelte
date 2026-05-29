<script lang="ts">
  interface Props {
    label?: string;
    onclick?: () => void;
    icon?: string;
    danger?: boolean;
    disabled?: boolean;
  }
  import Icon from './Icon.svelte';
  const { label, onclick, icon, danger = false, disabled = false }: Props = $props();
</script>

<button
  type="button"
  role="menuitem"
  {disabled}
  class="flex w-full items-center gap-sm px-sm py-2 text-left font-body-md text-body-md transition-colors disabled:cursor-not-allowed disabled:opacity-50 {danger ? 'text-error hover:bg-error-container/40' : 'text-on-surface hover:bg-surface-container-low'}"
  onclick={() => onclick?.()}
>
  {#if icon}<Icon name={icon} size={18} />{/if}
  <span>{label}</span>
</button>

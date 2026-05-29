<script lang="ts">
  import Icon from '$lib/components/ui/Icon.svelte';

  interface Props {
    onreject?: () => void;
    onsave?: () => void;
    onaccept?: () => void;
    onundo?: () => void;
    canUndo?: boolean;
    class?: string;
  }
  let {
    onreject,
    onsave,
    onaccept,
    onundo,
    canUndo = false,
    class: klass = ''
  }: Props = $props();
</script>

<div class="flex gap-lg items-center justify-center {klass}">
  {#if onundo}
    <button
      type="button"
      onclick={onundo}
      disabled={!canUndo}
      aria-label="Letzte Aktion rückgängig machen"
      class="
        w-12 h-12 rounded-full bg-surface-container-lowest shadow flex items-center justify-center
        text-on-surface-variant border border-surface-container active:scale-95
        disabled:opacity-40 disabled:cursor-not-allowed hover:text-primary transition-colors
      "
    >
      <Icon name="undo" size={22} />
    </button>
  {/if}

  <button
    type="button"
    onclick={onreject}
    aria-label="Ablehnen"
    class="
      w-16 h-16 rounded-full bg-surface-container-lowest shadow-[0px_4px_20px_rgba(47,79,79,0.08)]
      flex items-center justify-center text-error hover:bg-error-container transition-colors
      active:scale-95 border border-surface-container
    "
  >
    <Icon name="close" size={32} />
  </button>

  <button
    type="button"
    onclick={onsave}
    aria-label="Merken"
    class="
      w-16 h-16 rounded-full bg-surface-container-lowest shadow-[0px_4px_20px_rgba(47,79,79,0.08)]
      flex items-center justify-center text-secondary hover:bg-secondary-container transition-colors
      active:scale-95 border border-surface-container
    "
  >
    <Icon name="favorite" size={28} />
  </button>

  <button
    type="button"
    onclick={onaccept}
    aria-label="Bewerben"
    class="
      w-20 h-20 rounded-full bg-primary shadow-[0px_8px_30px_rgba(47,79,79,0.12)]
      flex items-center justify-center text-on-primary hover:bg-surface-tint
      transition-colors active:scale-95
    "
  >
    <Icon name="check" size={40} />
  </button>
</div>

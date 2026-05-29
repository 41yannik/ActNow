<script lang="ts">
  // Static map placeholder. Replace with real map later.
  import Icon from '$lib/components/ui/Icon.svelte';

  interface Props {
    city?: string | null;
    class?: string;
  }
  const { city = null, class: klass = '' }: Props = $props();
</script>

<div
  class="relative flex h-48 items-center justify-center overflow-hidden rounded-2xl border border-outline-variant bg-gradient-to-br from-primary/10 to-tertiary-fixed/30 {klass}"
  aria-label="Karte: {city ?? 'Standort'}"
>
  <Icon name="map" size={48} class="text-on-surface-variant/40" />
  {#if city}
    <span
      class="text-label-md font-label-md absolute bottom-sm left-sm rounded-full bg-surface-container-lowest/90 px-sm py-1 text-on-surface backdrop-blur-sm"
    >
      {city}
    </span>
  {/if}
</div>

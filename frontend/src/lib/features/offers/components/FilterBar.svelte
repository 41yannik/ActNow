<script lang="ts">
  // Horizontal scrollable chip filter for the Discover page.
  import Chip from '$lib/components/ui/Chip.svelte';
  import type { OfferType } from '$lib/types/database';
  import type { OfferFilters } from '$lib/stores/filters.svelte';

  interface Props {
    filters: OfferFilters;
    onchange: (patch: Partial<OfferFilters>) => void;
    class?: string;
  }
  const { filters, onchange, class: klass = '' }: Props = $props();

  const TYPES: { value: OfferType; label: string; icon: string }[] = [
    { value: 'single_event', label: 'Einmalig', icon: 'event' },
    { value: 'recurring_event', label: 'Regelmäßig', icon: 'repeat' },
    { value: 'flexible_task', label: 'Flexibel', icon: 'tune' },
    { value: 'digital_task', label: 'Digital', icon: 'wifi' }
  ];

  function toggleType(t: OfferType) {
    onchange({ offer_type: filters.offer_type === t ? null : t });
  }
</script>

<div
  class="no-scrollbar -mx-md flex items-center gap-xs overflow-x-auto px-md py-xs {klass}"
  role="toolbar"
  aria-label="Filter"
>
  {#each TYPES as t}
    <Chip
      label={t.label}
      icon={t.icon}
      variant={filters.offer_type === t.value ? 'selected' : 'filter'}
      onclick={() => toggleType(t.value)}
    />
  {/each}
  <Chip
    label="Ort"
    icon="location_on"
    variant={filters.location ? 'selected' : 'filter'}
    onclick={() => onchange({ location: filters.location ? null : 'Berlin' })}
  />
</div>

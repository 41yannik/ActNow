<script lang="ts">
  // Horizontal chip row to filter applications by status.
  import Chip from '$lib/components/ui/Chip.svelte';
  import type { ApplicationStatus } from '$lib/types/database';
  import { APPLICATION_STATUS_LABEL } from '$lib/utils/labels';

  interface Props {
    value: ApplicationStatus | 'all';
    options?: (ApplicationStatus | 'all')[];
    onchange: (next: ApplicationStatus | 'all') => void;
    class?: string;
  }
  const {
    value,
    options = ['all', 'submitted', 'shortlisted', 'accepted', 'rejected', 'completed'],
    onchange,
    class: klass = ''
  }: Props = $props();

  function label(o: ApplicationStatus | 'all') {
    return o === 'all' ? 'Alle' : APPLICATION_STATUS_LABEL[o];
  }
</script>

<div class="no-scrollbar flex gap-xs overflow-x-auto {klass}" role="toolbar" aria-label="Status">
  {#each options as o}
    <Chip label={label(o)} variant={value === o ? 'selected' : 'filter'} onclick={() => onchange(o)} />
  {/each}
</div>

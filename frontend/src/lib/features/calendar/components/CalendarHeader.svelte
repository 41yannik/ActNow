<script lang="ts">
  // Month header with navigation.
  import IconButton from '$lib/components/ui/IconButton.svelte';
  import { formatMonthYear } from '$lib/utils/format';

  interface Props {
    monthDate: Date;
    onprev?: () => void;
    onnext?: () => void;
    ontoday?: () => void;
    class?: string;
  }
  const { monthDate, onprev, onnext, ontoday, class: klass = '' }: Props = $props();
</script>

<header class="flex items-center justify-between gap-sm {klass}">
  <h2 class="font-h4 text-h4 text-on-surface capitalize">{formatMonthYear(monthDate)}</h2>
  <div class="flex items-center gap-xs">
    {#if ontoday}
      <button
        type="button"
        class="text-label-md font-label-md rounded-full px-sm py-1 text-primary hover:bg-primary/10"
        onclick={ontoday}>Heute</button
      >
    {/if}
    <IconButton icon="chevron_left" label="Vorheriger Monat" onclick={onprev} />
    <IconButton icon="chevron_right" label="Nächster Monat" onclick={onnext} />
  </div>
</header>

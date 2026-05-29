<script lang="ts">
  // A single day cell in the month grid.
  interface Props {
    date: Date;
    inMonth: boolean;
    today?: boolean;
    selected?: boolean;
    count?: number;
    onclick?: (d: Date) => void;
    class?: string;
  }
  const { date, inMonth, today = false, selected = false, count = 0, onclick, class: klass = '' }: Props =
    $props();
</script>

<button
  type="button"
  onclick={() => onclick?.(date)}
  class="
    relative flex h-12 w-full flex-col items-center justify-center rounded-lg text-sm
    transition-colors
    {inMonth ? 'text-on-surface' : 'text-on-surface-variant/40'}
    {selected ? 'bg-primary text-on-primary' : 'hover:bg-surface-container'}
    {today && !selected ? 'ring-1 ring-primary' : ''}
    {klass}
  "
  aria-pressed={selected}
  aria-label={date.toLocaleDateString('de-DE')}
>
  <span class="font-label-md text-label-md">{date.getDate()}</span>
  {#if count > 0}
    <span
      class="absolute bottom-1 h-1.5 w-1.5 rounded-full {selected ? 'bg-on-primary' : 'bg-primary'}"
      aria-label="{count} Termine"
    ></span>
  {/if}
</button>

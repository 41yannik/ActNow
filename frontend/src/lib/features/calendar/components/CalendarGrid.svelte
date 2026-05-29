<script lang="ts">
  // 6-row month grid with weekday header. Maps an event list (by ISO date) to day counts.
  import CalendarDayCell from './CalendarDayCell.svelte';

  interface Props {
    /** First day of month to display. */
    monthDate: Date;
    /** Events keyed by 'YYYY-MM-DD'. */
    eventsByDate?: Record<string, unknown[]>;
    selectedDate?: Date | null;
    onselect?: (d: Date) => void;
    class?: string;
  }
  const {
    monthDate,
    eventsByDate = {},
    selectedDate = null,
    onselect,
    class: klass = ''
  }: Props = $props();

  const WEEKDAYS = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  function toKey(d: Date) {
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  }

  function sameDay(a: Date, b: Date | null) {
    if (!b) return false;
    return a.getFullYear() === b.getFullYear() && a.getMonth() === b.getMonth() && a.getDate() === b.getDate();
  }

  const today = new Date();

  const cells = $derived.by(() => {
    const first = new Date(monthDate.getFullYear(), monthDate.getMonth(), 1);
    // Monday-first: getDay() returns 0=Sun .. 6=Sat → shift so Monday=0
    const weekdayOfFirst = (first.getDay() + 6) % 7;
    const start = new Date(first);
    start.setDate(first.getDate() - weekdayOfFirst);

    const out: { date: Date; inMonth: boolean }[] = [];
    for (let i = 0; i < 42; i++) {
      const d = new Date(start);
      d.setDate(start.getDate() + i);
      out.push({ date: d, inMonth: d.getMonth() === monthDate.getMonth() });
    }
    return out;
  });
</script>

<div class={klass}>
  <div class="mb-1 grid grid-cols-7 gap-1">
    {#each WEEKDAYS as w}
      <div class="text-center text-[12px] font-medium text-on-surface-variant">{w}</div>
    {/each}
  </div>
  <div class="grid grid-cols-7 gap-1">
    {#each cells as c (c.date.toISOString())}
      <CalendarDayCell
        date={c.date}
        inMonth={c.inMonth}
        today={sameDay(c.date, today)}
        selected={sameDay(c.date, selectedDate)}
        count={eventsByDate[toKey(c.date)]?.length ?? 0}
        onclick={(d) => onselect?.(d)}
      />
    {/each}
  </div>
</div>

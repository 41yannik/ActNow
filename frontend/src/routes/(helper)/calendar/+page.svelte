<script lang="ts">
  import { onMount } from 'svelte';
  import CalendarHeader from '$lib/features/calendar/components/CalendarHeader.svelte';
  import CalendarGrid from '$lib/features/calendar/components/CalendarGrid.svelte';
  import EventCard from '$lib/features/calendar/components/EventCard.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import { listApplicationsForHelper } from '$lib/services/supabase/applications';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { APPLICATION_STATUS_LABEL } from '$lib/utils/labels';
  import type { ApplicationRow, ApplicationWithOffer, OfferRow, ProfileRow } from '$lib/types/database';

  interface Event {
    application: ApplicationRow;
    offer: Pick<OfferRow, 'id' | 'title' | 'starts_at' | 'ends_at' | 'city' | 'is_remote'>;
    org: Pick<ProfileRow, 'display_name'> | null;
  }

  let loading = $state(true);
  let events = $state<Event[]>([]);
  let monthDate = $state(startOfMonth(new Date()));
  let selectedDate = $state<Date | null>(new Date());

  function startOfMonth(d: Date) {
    return new Date(d.getFullYear(), d.getMonth(), 1);
  }
  function dayKey(iso: string) {
    const d = new Date(iso);
    return `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`;
  }

  async function load() {
    if (!auth.profile) return;
    loading = true;
    try {
      const rows = await listApplicationsForHelper(auth.profile.id, ['accepted', 'completed']);
      events = rows
        .filter((r) => r.offer?.starts_at)
        .map((r: ApplicationWithOffer) => ({
          application: r as ApplicationRow,
          offer: r.offer!,
          org: r.offer?.organization?.profile ?? null
        }));
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Termine nicht laden');
    } finally {
      loading = false;
    }
  }

  onMount(load);

  const eventsByDate = $derived.by(() => {
    const out: Record<string, Event[]> = {};
    for (const e of events) {
      if (!e.offer.starts_at) continue;
      const k = dayKey(e.offer.starts_at);
      (out[k] ??= []).push(e);
    }
    return out;
  });

  const selectedKey = $derived(selectedDate ? dayKey(selectedDate.toISOString()) : null);
  const selectedEvents = $derived(selectedKey ? (eventsByDate[selectedKey] ?? []) : []);
</script>

<svelte:head><title>Kalender · ActNow</title></svelte:head>

<section class="mx-auto flex w-full max-w-3xl flex-col gap-md p-md">
  <CalendarHeader
    {monthDate}
    onprev={() => (monthDate = new Date(monthDate.getFullYear(), monthDate.getMonth() - 1, 1))}
    onnext={() => (monthDate = new Date(monthDate.getFullYear(), monthDate.getMonth() + 1, 1))}
    ontoday={() => {
      monthDate = startOfMonth(new Date());
      selectedDate = new Date();
    }}
  />

  {#if loading}
    <div class="flex justify-center py-lg"><LoadingSpinner /></div>
  {:else}
    <CalendarGrid {monthDate} {eventsByDate} {selectedDate} onselect={(d) => (selectedDate = d)} />

    <div class="mt-md flex flex-col gap-sm">
      <h3 class="font-h4 text-h4 text-on-surface">
        {selectedDate?.toLocaleDateString('de-DE', { dateStyle: 'full' }) ?? 'Termine'}
      </h3>
      {#if selectedEvents.length === 0}
        <EmptyState icon="event_busy" title="Keine Termine" description="An diesem Tag hast du keine Einsätze." />
      {:else}
        {#each selectedEvents as ev (ev.application.id)}
          <EventCard
            title={ev.offer.title}
            organizationName={ev.org?.display_name ?? ''}
            startsAt={ev.offer.starts_at!}
            endsAt={ev.offer.ends_at}
            location={ev.offer.city}
            isRemote={ev.offer.is_remote}
            statusLabel={APPLICATION_STATUS_LABEL[ev.application.status]}
          />
        {/each}
      {/if}
    </div>
  {/if}
</section>

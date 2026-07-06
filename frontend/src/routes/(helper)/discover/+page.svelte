<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import SageHeader from '$lib/components/layout/SageHeader.svelte';
  import SwipeDeck from '$lib/features/offers/components/SwipeDeck.svelte';
  import SwipeActionBar from '$lib/features/offers/components/SwipeActionBar.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Icon from '$lib/components/ui/Icon.svelte';
  import { searchOffers } from '$lib/services/supabase/offers';
  import { createApplication } from '$lib/services/supabase/applications';
  import { listSavedOfferIds, saveOffer, unsaveOffer } from '$lib/services/supabase/savedOffers';
  import { offerFromSearchResult, type Offer } from '$lib/types/domain';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import type { SwipeEvent } from '$lib/features/offers/components/swipe.types';

  let offers = $state<Offer[]>([]);
  let loading = $state(true);
  let savedIds = $state<Set<string>>(new Set());
  let deck = $state<SwipeDeck>();
  let canUndo = $state(false);

  // ── Day strip (visual): 14 days starting today, "today" highlighted. ──
  const today = new Date();
  const days = Array.from({ length: 14 }, (_, i) => {
    const d = new Date(today);
    d.setDate(today.getDate() + i);
    return {
      key: d.toISOString().slice(0, 10),
      dow: d.toLocaleDateString('de-DE', { weekday: 'short' }).replace('.', ''),
      day: d.getDate(),
      today: i === 0,
    };
  });
  let selectedDay = $state(days[0].key);

  const greeting = $derived(
    auth.profile
      ? `Hallo ${auth.profile.display_name?.split(' ')[0] ?? ''} 👋${auth.profile.city ? ` · ${auth.profile.city}` : ''}`
      : 'Finde deinen nächsten Einsatz',
  );

  async function load() {
    loading = true;
    try {
      const rows = await searchOffers({ limit: 25 });
      offers = rows.map(offerFromSearchResult);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Angebote nicht laden');
    } finally {
      loading = false;
    }
  }

  async function loadSaved() {
    if (!auth.profile) return;
    try {
      savedIds = await listSavedOfferIds(auth.profile.id);
    } catch {
      // non-fatal — favorite state just starts empty
    }
  }

  onMount(() => {
    void load();
    void loadSaved();
  });

  async function onSwipe(e: SwipeEvent) {
    canUndo = true;
    if (e.direction === 'left') {
      return; // skip silently
    }
    if (!auth.profile) return;
    const offer = offers.find((o) => o.id === e.offerId);
    if (!offer) return;
    try {
      await createApplication({
        offer_id: offer.id,
        helper_profile_id: auth.profile.id,
        motivation_text: null,
      });
      toasts.success('Bewerbung gesendet · +100 Punkte', offer.title);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Bewerbung fehlgeschlagen');
    }
  }

  async function toggleSave(offerId: string) {
    if (!auth.profile) return;
    const isSaved = savedIds.has(offerId);
    // optimistic
    const next = new Set(savedIds);
    isSaved ? next.delete(offerId) : next.add(offerId);
    savedIds = next;
    try {
      if (isSaved) {
        await unsaveOffer(auth.profile.id, offerId);
      } else {
        await saveOffer(auth.profile.id, offerId);
        toasts.success('In Favoriten gespeichert');
      }
    } catch (err) {
      // revert on failure
      const revert = new Set(savedIds);
      isSaved ? revert.add(offerId) : revert.delete(offerId);
      savedIds = revert;
      toasts.error(err instanceof Error ? err.message : 'Konnte nicht speichern');
    }
  }

  function saveTop() {
    const id = deck?.topOfferId();
    if (id) void toggleSave(id);
  }
</script>

<svelte:head><title>Entdecken · ActNow</title></svelte:head>

<section class="mx-auto flex w-full max-w-2xl flex-col">
  <SageHeader title="Entdecke" subtitle={greeting} unread={2}>
    {#snippet titleTrailing()}
      <a
        href="/calendar"
        class="flex items-center gap-2 rounded-xl bg-white/95 px-3.5 py-2 text-[13px] font-semibold text-secondary shadow-sm transition-transform active:scale-95"
      >
        <Icon name="calendar_today" size={16} />
        Kalender
      </a>
    {/snippet}
  </SageHeader>

  <!-- Day strip -->
  <div class="no-scrollbar overflow-x-auto border-b border-outline-variant px-4 py-3.5">
    <div class="flex gap-1.5">
      {#each days as d}
        {@const sel = d.key === selectedDay}
        <button
          type="button"
          onclick={() => (selectedDay = d.key)}
          class="flex w-[46px] shrink-0 flex-col items-center gap-0.5 rounded-xl py-1.5 transition-colors
                 {sel ? 'bg-primary' : 'bg-transparent'}"
        >
          <span class="text-[11px] font-medium {sel ? 'text-white/85' : 'text-on-surface-variant'}"
            >{d.dow}</span
          >
          <span class="text-[17px] font-bold {sel ? 'text-white' : 'text-on-surface'}">{d.day}</span
          >
          {#if !sel && d.today}
            <span class="-mt-0.5 h-1 w-1 rounded-full bg-primary"></span>
          {/if}
        </button>
      {/each}
    </div>
  </div>

  <!-- Swipe stack -->
  <div class="relative mx-auto w-full max-w-md px-4 pt-4">
    {#if loading}
      <div class="flex h-[520px] items-center justify-center"><LoadingSpinner /></div>
    {:else if offers.length === 0}
      <div class="flex h-[520px] items-center justify-center">
        <EmptyState
          icon="search_off"
          title="Keine Angebote"
          description="Schau später wieder vorbei – neue Einsätze kommen laufend dazu."
        >
          {#snippet action()}
            <Button onclick={load}>Neu laden</Button>
          {/snippet}
        </EmptyState>
      </div>
    {:else}
      <SwipeDeck
        bind:this={deck}
        {offers}
        {savedIds}
        onswipe={onSwipe}
        onempty={load}
        ontogglesave={toggleSave}
        onopendetail={(id) => goto(`/offers/${id}`)}
      />
    {/if}
  </div>

  <!-- Action buttons + hints -->
  {#if !loading && offers.length > 0}
    <div class="px-6 pt-2">
      <SwipeActionBar
        onreject={() => deck?.swipeLeft()}
        onsave={saveTop}
        onaccept={() => deck?.swipeRight()}
        onundo={() => deck?.undoLast()}
        {canUndo}
      />
    </div>
  {/if}
</section>

<script lang="ts">
  import { onMount } from 'svelte';
  import SwipeDeck from '$lib/features/offers/components/SwipeDeck.svelte';
  import FilterBar from '$lib/features/offers/components/FilterBar.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import { searchOffers } from '$lib/services/supabase/offers';
  import { createApplication } from '$lib/services/supabase/applications';
  import { offerFromSearchResult, type Offer } from '$lib/types/domain';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { readFilters, writeFilters, type OfferFilters } from '$lib/stores/filters.svelte';
  import { page } from '$app/state';
  import type { SwipeEvent } from '$lib/features/offers/components/swipe.types';

  let offers = $state<Offer[]>([]);
  let loading = $state(true);
  let filters = $state<OfferFilters>(readFilters(page.url.searchParams));

  async function load() {
    loading = true;
    try {
      const rows = await searchOffers({
        offer_type: filters.offer_type ?? undefined,
        location: filters.location ?? undefined,
        available_from: filters.available_from ?? undefined,
        tags: filters.tags?.length ? filters.tags : undefined,
        limit: 25
      });
      offers = rows.map(offerFromSearchResult);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Angebote nicht laden');
    } finally {
      loading = false;
    }
  }

  onMount(load);

  function onFilterChange(patch: Partial<OfferFilters>) {
    filters = { ...filters, ...patch };
    writeFilters(patch);
    void load();
  }

  async function onSwipe(e: SwipeEvent) {
    if (e.direction !== 'right') return;
    if (!auth.profile) return;
    const offer = offers.find((o) => o.id === e.offerId);
    if (!offer) return;
    try {
      await createApplication({
        offer_id: offer.id,
        helper_profile_id: auth.profile.id,
        motivation_text: null
      });
      toasts.success('Bewerbung gesendet', offer.title);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Bewerbung fehlgeschlagen');
    }
  }
</script>

<svelte:head><title>Entdecken · ActNow</title></svelte:head>

<section class="mx-auto flex w-full max-w-2xl flex-col gap-md p-md">
  <FilterBar {filters} onchange={onFilterChange} />

  <div class="relative mx-auto h-[70vh] w-full max-w-md">
    {#if loading}
      <div class="flex h-full items-center justify-center"><LoadingSpinner /></div>
    {:else if offers.length === 0}
      <EmptyState
        icon="search_off"
        title="Keine Angebote"
        description="Erweitere deine Filter, um mehr Angebote zu sehen."
      >
        {#snippet action()}
          <Button onclick={() => onFilterChange({ offer_type: null, location: null })}>
            Filter zurücksetzen
          </Button>
        {/snippet}
      </EmptyState>
    {:else}
      <SwipeDeck {offers} onswipe={onSwipe} onempty={load} />
    {/if}
  </div>
</section>

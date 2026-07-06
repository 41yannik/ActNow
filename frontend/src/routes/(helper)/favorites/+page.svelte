<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import SageHeader from '$lib/components/layout/SageHeader.svelte';
  import Alert from '$lib/components/ui/Alert.svelte';
  import Badge from '$lib/components/ui/Badge.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import Icon from '$lib/components/ui/Icon.svelte';
  import IconButton from '$lib/components/ui/IconButton.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import { getCommunitySummary } from '$lib/services/supabase/messages';
  import { listSavedOffers, unsaveOffer } from '$lib/services/supabase/savedOffers';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import type {
    CommunitySummary,
    OfferRow,
    OfferStatus,
    SavedOfferWithOffer,
  } from '$lib/types/database';
  import { formatDate, formatRelative } from '$lib/utils/format';
  import { OFFER_STATUS_LABEL } from '$lib/utils/labels';

  const UNAVAILABLE_STATUSES = new Set<OfferStatus>([
    'paused',
    'filled',
    'completed',
    'cancelled',
    'archived',
  ]);

  let loading = $state(true);
  let errorMessage = $state<string | null>(null);
  let favorites = $state<SavedOfferWithOffer[]>([]);
  let removingIds = $state<Set<string>>(new Set());
  let summary = $state<CommunitySummary>({
    unread_messages: 0,
    unread_notifications: 0,
    total_unread: 0,
  });

  const visibleCount = $derived(favorites.filter((item) => item.offer).length);

  onMount(() => {
    void load();
  });

  async function load() {
    loading = true;
    errorMessage = null;
    try {
      const summaryPromise = getCommunitySummary().catch(() => summary);
      if (!auth.profile) {
        favorites = [];
        summary = await summaryPromise;
        errorMessage = 'Dein Profil konnte nicht geladen werden.';
        return;
      }

      const [rows, unread] = await Promise.all([listSavedOffers(auth.profile.id), summaryPromise]);
      favorites = rows;
      summary = unread;
    } catch (err) {
      errorMessage = err instanceof Error ? err.message : 'Favoriten konnten nicht geladen werden.';
      toasts.error(errorMessage);
    } finally {
      loading = false;
    }
  }

  function isUnavailable(offer: OfferRow | null): boolean {
    return !offer || UNAVAILABLE_STATUSES.has(offer.status);
  }

  function statusText(offer: OfferRow | null): string {
    if (!offer || isUnavailable(offer)) return 'Nicht verfügbar';
    return OFFER_STATUS_LABEL[offer.status];
  }

  function titleText(offer: OfferRow | null): string {
    return offer?.title ?? 'Gespeichertes Angebot nicht mehr verfügbar';
  }

  function locationText(offer: OfferRow | null): string {
    if (!offer) return 'Angebot nicht mehr erreichbar';
    if (offer.is_remote) return 'Remote';
    return offer.city ?? offer.location_name ?? 'Vor Ort';
  }

  function dateText(offer: OfferRow | null): string {
    if (!offer) return 'Keine Details verfügbar';
    return offer.starts_at ? formatDate(offer.starts_at) : 'Flexibel';
  }

  function categoryText(offer: OfferRow | null): string {
    return offer?.category ?? 'Allgemein';
  }

  function setRemoving(id: string, value: boolean) {
    const next = new Set(removingIds);
    if (value) next.add(id);
    else next.delete(id);
    removingIds = next;
  }

  async function removeFavorite(item: SavedOfferWithOffer) {
    if (!auth.profile || removingIds.has(item.id)) return;
    const previous = favorites;
    favorites = favorites.filter((favorite) => favorite.id !== item.id);
    setRemoving(item.id, true);
    try {
      await unsaveOffer(auth.profile.id, item.offer_id);
      toasts.success('Aus Favoriten entfernt');
    } catch (err) {
      favorites = previous;
      toasts.error(err instanceof Error ? err.message : 'Favorit konnte nicht entfernt werden.');
    } finally {
      setRemoving(item.id, false);
    }
  }

  function openOffer(offer: OfferRow | null) {
    if (offer) void goto(`/offers/${offer.id}`);
  }
</script>

<svelte:head><title>Favoriten · ActNow</title></svelte:head>

<section class="mx-auto w-full max-w-2xl">
  <SageHeader
    title="Favoriten"
    subtitle={visibleCount === 1
      ? '1 gespeichertes Angebot'
      : `${visibleCount} gespeicherte Angebote`}
    unread={summary.total_unread}
    onbell={() => goto('/community')}
  />

  <div class="space-y-md p-md">
    {#if loading}
      <div class="flex min-h-[420px] items-center justify-center">
        <LoadingSpinner />
      </div>
    {:else if errorMessage}
      <Alert tone="error" title="Favoriten nicht geladen">
        <div class="space-y-sm">
          <p>{errorMessage}</p>
          <Button variant="outlined" size="sm" onclick={load}>Erneut versuchen</Button>
        </div>
      </Alert>
    {:else if favorites.length === 0}
      <div class="flex min-h-[420px] items-center justify-center">
        <EmptyState
          icon="favorite"
          title="Noch keine Favoriten"
          description="Gespeicherte Angebote aus Entdecken erscheinen hier als kompakte Liste."
        >
          {#snippet action()}
            <Button onclick={() => goto('/discover')} leadingIcon="search"
              >Angebote entdecken</Button
            >
          {/snippet}
        </EmptyState>
      </div>
    {:else}
      <div class="space-y-sm">
        {#each favorites as item (item.id)}
          {@const offer = item.offer}
          {@const unavailable = isUnavailable(offer)}
          <article
            class="flex gap-sm rounded-lg border p-md shadow-sm transition-colors
                {unavailable
              ? 'border-error/35 bg-error-container/10'
              : 'border-outline-variant bg-surface'}"
          >
            <div
              class="flex h-11 w-11 shrink-0 items-center justify-center rounded-lg
                  {unavailable
                ? 'bg-error-container text-on-error-container'
                : 'bg-primary-container text-white'}"
            >
              <Icon
                name={unavailable ? 'event_busy' : 'bookmark'}
                filled={!unavailable}
                size={22}
              />
            </div>

            <div class="min-w-0 flex-1">
              <div class="flex flex-wrap items-start justify-between gap-xs">
                <h2
                  class="min-w-0 flex-1 break-words text-[15px] font-bold leading-snug text-on-secondary-container"
                >
                  {titleText(offer)}
                </h2>
                <Badge tone={unavailable ? 'danger' : 'success'}>{statusText(offer)}</Badge>
              </div>

              {#if offer?.description}
                <p class="mt-1 line-clamp-2 text-[13px] leading-relaxed text-on-surface-variant">
                  {offer.description}
                </p>
              {/if}

              <div
                class="mt-sm flex flex-wrap gap-x-md gap-y-xs text-[12px] font-medium text-on-surface-variant"
              >
                <span class="inline-flex items-center gap-1">
                  <Icon name={offer?.is_remote ? 'language' : 'location_on'} size={14} />
                  {locationText(offer)}
                </span>
                <span class="inline-flex items-center gap-1">
                  <Icon name="calendar_today" size={14} />
                  {dateText(offer)}
                </span>
                <span class="inline-flex items-center gap-1">
                  <Icon name="category" size={14} />
                  {categoryText(offer)}
                </span>
              </div>

              <div class="mt-sm flex flex-wrap items-center justify-between gap-sm">
                <span class="text-[11px] text-on-surface-variant">
                  Gespeichert {formatRelative(item.created_at)}
                </span>
                <div class="flex items-center gap-xs">
                  <Button
                    variant="outlined"
                    size="sm"
                    disabled={!offer}
                    onclick={() => openOffer(offer)}
                  >
                    Öffnen
                  </Button>
                  <IconButton
                    icon={removingIds.has(item.id) ? 'progress_activity' : 'delete'}
                    label="Aus Favoriten entfernen"
                    tone="danger"
                    size="sm"
                    disabled={removingIds.has(item.id)}
                    class={removingIds.has(item.id) ? 'animate-spin' : ''}
                    onclick={() => removeFavorite(item)}
                  />
                </div>
              </div>
            </div>
          </article>
        {/each}
      </div>
    {/if}
  </div>
</section>

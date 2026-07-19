<script lang="ts">
  import type { Offer } from '$lib/types/domain';
  import Icon from '$lib/components/ui/Icon.svelte';
  import CategoryBadge from '$lib/components/ui/CategoryBadge.svelte';
  import { enrichOffer } from '../mockEnrich';

  interface Props {
    offer: Offer;
    /** Horizontal drag distance in px (used to render swipe-indicator overlays). */
    dragX?: number;
    /** Distance threshold so overlay can fade in proportionally. */
    threshold?: number;
    /** Whether the offer is in favorites. */
    saved?: boolean;
    ontogglesave?: () => void;
    onopen?: () => void;
    class?: string;
  }
  let {
    offer,
    dragX = 0,
    threshold = 100,
    saved = false,
    ontogglesave,
    onopen,
    class: klass = '',
  }: Props = $props();

  const likeOpacity = $derived(Math.min(Math.max(dragX, 0) / threshold, 1));
  const nopeOpacity = $derived(Math.min(Math.max(-dragX, 0) / threshold, 1));

  // Deterministic presentation details for the static fixture — see mockEnrich.ts.
  const meta = $derived(enrichOffer(offer.id));

  const scheduleText = $derived(
    offer.schedule_text ??
      (offer.starts_at
        ? new Date(offer.starts_at).toLocaleString('de-DE', {
            weekday: 'short',
            day: '2-digit',
            month: 'short',
            hour: '2-digit',
            minute: '2-digit',
          })
        : 'Flexibel'),
  );

  const durationText = $derived(
    offer.starts_at && offer.ends_at
      ? `Dauer ${Math.max(
          1,
          Math.round(
            (new Date(offer.ends_at).getTime() - new Date(offer.starts_at).getTime()) / 3.6e6,
          ),
        )} Std.`
      : null,
  );

  const locationText = $derived(
    offer.is_remote ? 'Digital / Remote' : `${offer.city ?? 'Vor Ort'} · ${meta.km} km entfernt`,
  );

  const friendLabel = $derived(
    meta.friends.length === 1
      ? `${meta.friends[0]} ist dabei`
      : `${meta.friends[0]} +${meta.friends.length - 1} dabei`,
  );

  function toggleSave(e: MouseEvent) {
    e.stopPropagation();
    ontogglesave?.();
  }
</script>

<div
  class="relative flex h-full w-full flex-col overflow-hidden rounded-card border border-outline-variant/30 bg-surface
         shadow-[0_12px_36px_rgba(40,50,30,0.16),_0_2px_6px_rgba(40,50,30,0.06)] {klass}"
  role="button"
  tabindex="0"
  aria-roledescription="swipe-card"
  aria-label={`Angebot: ${offer.title} von ${offer.organization_name}`}
  onclick={() => onopen?.()}
  onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && onopen?.()}
>
  <!-- Image header -->
  <div class="relative h-[55%] w-full bg-surface-container-low">
    {#if offer.cover_image_url}
      <img
        src={offer.cover_image_url}
        alt=""
        class="h-full w-full object-cover"
        draggable="false"
        loading="lazy"
      />
    {:else}
      <div
        class="flex h-full w-full items-center justify-center bg-gradient-to-br from-secondary-container to-primary"
      >
        <Icon name="volunteer_activism" size={64} class="text-white/40" />
      </div>
    {/if}

    <!-- Category badge -->
    {#if offer.category}
      <div class="absolute left-3 top-3 z-10">
        <CategoryBadge category={offer.category} />
      </div>
    {/if}

    <!-- SOS pill (mock) -->
    {#if meta.sos}
      <div
        class="absolute right-14 top-3 z-10 flex items-center gap-1 rounded-full bg-tertiary px-2.5 py-1
               text-[10px] font-bold tracking-wider text-white"
      >
        <span class="h-1.5 w-1.5 rounded-full bg-white"></span>
        SOS
      </div>
    {/if}

    <!-- Favorite -->
    <button
      type="button"
      onclick={toggleSave}
      aria-label={saved ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen'}
      class="absolute right-3 top-3 z-10 flex h-9 w-9 items-center justify-center rounded-full
             border-none bg-white/95 text-secondary shadow-sm transition-transform active:scale-90"
    >
      <Icon name="favorite" filled={saved} size={20} />
    </button>

    <!-- Friends pill (mock) -->
    {#if meta.friends.length > 0}
      <div
        class="absolute bottom-3 left-3 z-10 flex max-w-[calc(100%-1.5rem)] items-center gap-1.5
               rounded-full bg-white/95 py-1 pl-1 pr-2.5 shadow-sm"
      >
        <div class="flex">
          {#each meta.friends.slice(0, 2) as f, i}
            <div
              class="flex h-5 w-5 items-center justify-center rounded-full border-[1.5px] border-white text-[9px] font-bold text-white"
              style="background: {['#A4B097', '#B8A57E'][i]}; margin-left: {i === 0 ? 0 : -6}px;"
            >
              {f[0]}
            </div>
          {/each}
        </div>
        <span class="truncate text-[11px] font-semibold text-on-secondary-container"
          >{friendLabel}</span
        >
      </div>
    {/if}

    <!-- LIKE / NOPE overlays -->
    <div
      class="pointer-events-none absolute left-6 top-6 -rotate-12 rounded-lg border-4 border-primary
             bg-white/10 px-3 py-1.5 text-[18px] font-extrabold tracking-wider text-primary transition-opacity"
      style="opacity: {likeOpacity}"
      aria-hidden="true"
    >
      BEWERBEN
    </div>
    <div
      class="pointer-events-none absolute right-6 top-6 rotate-12 rounded-lg border-4 border-[#C9655B]
             bg-white/10 px-3 py-1.5 text-[18px] font-extrabold tracking-wider text-[#C9655B] transition-opacity"
      style="opacity: {nopeOpacity}"
      aria-hidden="true"
    >
      NICHTS FÜR DICH
    </div>
  </div>

  <!-- Body -->
  <div class="flex flex-1 flex-col gap-2.5 p-[18px]">
    <h2
      class="line-clamp-2 text-[19px] font-bold leading-tight tracking-tight text-on-secondary-container"
    >
      {offer.title}
    </h2>

    <div class="flex flex-col gap-1.5 text-on-surface-variant">
      <div class="flex items-center gap-2">
        <Icon name={offer.is_remote ? 'wifi' : 'location_on'} size={14} />
        <span class="truncate text-[12.5px]">{locationText}</span>
      </div>
      <div class="flex items-center gap-2">
        <Icon name="calendar_today" size={13} />
        <span class="truncate text-[12.5px]">{scheduleText}</span>
      </div>
      {#if durationText}
        <div class="flex items-center gap-2">
          <Icon name="schedule" size={13} />
          <span class="truncate text-[12.5px]">{durationText}</span>
        </div>
      {/if}
    </div>

    <p class="line-clamp-2 text-[13px] leading-relaxed text-on-surface">{offer.description}</p>

    <!-- Calendar match badge (mock) -->
    <div
      class="mt-auto inline-flex items-center gap-1.5 self-start rounded-full px-2.5 py-1.5"
      style="background: {meta.match === 'fits'
        ? 'rgba(126,143,107,0.14)'
        : 'rgba(226,148,90,0.14)'};"
    >
      <Icon
        name={meta.match === 'fits' ? 'check_circle' : 'schedule'}
        size={12}
        class={meta.match === 'fits' ? 'text-secondary' : 'text-tertiary'}
      />
      <span
        class="text-[11px] font-semibold {meta.match === 'fits'
          ? 'text-secondary'
          : 'text-tertiary'}"
      >
        {meta.match === 'fits' ? 'Passt in deinen Kalender' : 'Teilweise im Kalender'}
      </span>
    </div>
  </div>
</div>

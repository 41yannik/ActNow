<script lang="ts">
  import type { Offer } from '$lib/types/domain';
  import Icon from '$lib/components/ui/Icon.svelte';
  import OrgLogo from '$lib/components/ui/OrgLogo.svelte';
  import RatingStars from '$lib/components/ui/RatingStars.svelte';

  interface Props {
    offer: Offer;
    /** Horizontal drag distance in px (used to render swipe-indicator overlays). */
    dragX?: number;
    /** Distance threshold so overlay can fade in proportionally. */
    threshold?: number;
    class?: string;
  }
  let { offer, dragX = 0, threshold = 100, class: klass = '' }: Props = $props();

  const likeOpacity = $derived(Math.min(Math.max(dragX, 0) / threshold, 1));
  const nopeOpacity = $derived(Math.min(Math.max(-dragX, 0) / threshold, 1));

  const scheduleText = $derived(
    offer.schedule_text ??
      (offer.starts_at
        ? new Date(offer.starts_at).toLocaleString('de-DE', {
            weekday: 'long',
            day: '2-digit',
            month: 'long',
            hour: '2-digit',
            minute: '2-digit'
          })
        : 'Flexibel')
  );

  const locationText = $derived(
    offer.is_remote
      ? 'Digital / Remote'
      : [offer.city, offer.is_remote ? null : '(Vor Ort)'].filter(Boolean).join(' ')
  );
</script>

<article
  class="
    w-full h-full bg-surface-container-lowest rounded-3xl
    shadow-[0px_8px_30px_rgba(47,79,79,0.12)] overflow-hidden
    flex flex-col border border-surface-container-high
    {klass}
  "
  aria-roledescription="swipe-card"
  aria-label={`Angebot: ${offer.title} von ${offer.organization_name}`}
>
  <!-- Image header -->
  <div class="relative h-1/2 w-full bg-surface-variant">
    {#if offer.cover_image_url}
      <img
        src={offer.cover_image_url}
        alt=""
        class="w-full h-full object-cover"
        draggable="false"
        loading="lazy"
      />
    {:else}
      <div class="w-full h-full bg-gradient-to-br from-primary-fixed to-tertiary-fixed flex items-center justify-center">
        <Icon name="volunteer_activism" size={64} class="text-on-primary-fixed/50" />
      </div>
    {/if}

    {#if offer.organization_rating != null && offer.organization_rating > 0}
      <div
        class="absolute top-sm right-sm bg-surface-container-lowest/90 backdrop-blur-sm rounded-full
               px-sm py-1 flex items-center gap-xs shadow-sm"
      >
        <RatingStars value={offer.organization_rating} count={null} showValue size={14} />
      </div>
    {/if}

    <div
      class="absolute bottom-0 left-0 w-full h-1/2 bg-gradient-to-t from-surface-container-lowest to-transparent"
    ></div>

    <!-- LIKE / NOPE overlays -->
    <div
      class="absolute top-6 left-6 px-3 py-1.5 rounded-lg border-4 border-primary text-primary
             font-h3 text-h3 -rotate-12 pointer-events-none transition-opacity"
      style="opacity: {likeOpacity}"
      aria-hidden="true"
    >
      LIKE
    </div>
    <div
      class="absolute top-6 right-6 px-3 py-1.5 rounded-lg border-4 border-error text-error
             font-h3 text-h3 rotate-12 pointer-events-none transition-opacity"
      style="opacity: {nopeOpacity}"
      aria-hidden="true"
    >
      NOPE
    </div>
  </div>

  <!-- Content -->
  <div class="p-md flex-grow flex flex-col justify-between bg-surface-container-lowest relative">
    <div class="absolute -top-8 left-md">
      <OrgLogo src={offer.organization_avatar_url} name={offer.organization_name} size="md" />
    </div>
    <div class="mt-sm">
      <h2 class="font-h3 text-h3 text-on-surface mb-xs line-clamp-2">{offer.title}</h2>
      <p class="font-label-md text-label-md text-on-surface-variant mb-md">
        {offer.organization_name}
      </p>
      <div class="flex flex-col gap-2 mb-md text-on-surface-variant">
        {#if locationText}
          <div class="flex items-center gap-sm">
            <Icon name={offer.is_remote ? 'wifi' : 'location_on'} size={20} />
            <span class="font-body-md text-body-md">{locationText}</span>
          </div>
        {/if}
        <div class="flex items-center gap-sm">
          <Icon name="schedule" size={20} />
          <span class="font-body-md text-body-md">{scheduleText}</span>
        </div>
      </div>
      <p class="font-body-md text-body-md text-on-surface line-clamp-3">
        {offer.description}
      </p>
    </div>
  </div>
</article>

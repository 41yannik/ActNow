<script lang="ts">
  // Shared offer image header (cover image / fallback gradient + rating badge).
  import Icon from '$lib/components/ui/Icon.svelte';
  import RatingStars from '$lib/components/ui/RatingStars.svelte';

  interface Props {
    cover_image_url?: string | null;
    organization_rating?: number | null;
    /** Tailwind height class. Defaults to h-48. */
    heightClass?: string;
    /** Show the LIKE/NOPE overlays (swipe context only). */
    showSwipeOverlays?: boolean;
    likeOpacity?: number;
    nopeOpacity?: number;
    class?: string;
  }
  const {
    cover_image_url = null,
    organization_rating = null,
    heightClass = 'h-48',
    showSwipeOverlays = false,
    likeOpacity = 0,
    nopeOpacity = 0,
    class: klass = '',
  }: Props = $props();
</script>

<div class="relative w-full {heightClass} bg-surface-variant {klass}">
  {#if cover_image_url}
    <img
      src={cover_image_url}
      alt=""
      class="h-full w-full object-cover"
      draggable="false"
      loading="lazy"
    />
  {:else}
    <div
      class="flex h-full w-full items-center justify-center bg-gradient-to-br from-primary-fixed to-tertiary-fixed"
    >
      <Icon name="volunteer_activism" size={48} class="text-on-primary-fixed/50" />
    </div>
  {/if}

  {#if organization_rating != null && organization_rating > 0}
    <div
      class="absolute top-sm right-sm flex items-center gap-xs rounded-full bg-surface-container-lowest/90 px-sm py-1 shadow-sm backdrop-blur-sm"
    >
      <RatingStars value={organization_rating} count={null} showValue size={14} />
    </div>
  {/if}

  <div
    class="pointer-events-none absolute bottom-0 left-0 h-1/2 w-full bg-gradient-to-t from-surface-container-lowest to-transparent"
  ></div>

  {#if showSwipeOverlays}
    <div
      class="font-h3 text-h3 pointer-events-none absolute top-6 left-6 -rotate-12 rounded-lg border-4 border-primary px-3 py-1.5 text-primary transition-opacity"
      style="opacity: {likeOpacity}"
      aria-hidden="true"
    >
      LIKE
    </div>
    <div
      class="font-h3 text-h3 pointer-events-none absolute top-6 right-6 rotate-12 rounded-lg border-4 border-error px-3 py-1.5 text-error transition-opacity"
      style="opacity: {nopeOpacity}"
      aria-hidden="true"
    >
      NOPE
    </div>
  {/if}
</div>

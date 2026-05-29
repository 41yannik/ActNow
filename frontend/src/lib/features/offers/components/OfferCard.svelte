<script lang="ts">
  // Compact offer card (list / grid view). Reuses Badge/OrgLogo/Icon.
  import type { Offer } from '$lib/types/domain';
  import Icon from '$lib/components/ui/Icon.svelte';
  import OrgLogo from '$lib/components/ui/OrgLogo.svelte';
  import Badge from '$lib/components/ui/Badge.svelte';
  import OfferMediaHeader from './OfferMediaHeader.svelte';
  import { formatDate } from '$lib/utils/format';
  import { OFFER_STATUS_LABEL } from '$lib/utils/labels';

  interface Props {
    offer: Offer;
    href?: string;
    class?: string;
    /** Hide the image header (denser list variant). */
    compact?: boolean;
  }
  const { offer, href, class: klass = '', compact = false }: Props = $props();

  const locationText = $derived(offer.is_remote ? 'Digital / Remote' : (offer.city ?? ''));
  const scheduleText = $derived(
    offer.starts_at ? formatDate(offer.starts_at) : 'Flexibel'
  );

  const Tag = $derived(href ? 'a' : 'article');
</script>

<svelte:element
  this={Tag}
  href={href}
  class="block overflow-hidden rounded-2xl border border-outline-variant bg-surface-container-lowest transition-shadow hover:shadow-lg {klass}"
>
  {#if !compact}
    <OfferMediaHeader
      cover_image_url={offer.cover_image_url}
      organization_rating={offer.organization_rating}
      heightClass="h-36"
    />
  {/if}
  <div class="flex flex-col gap-xs p-md">
    <div class="flex items-start gap-sm">
      <OrgLogo src={offer.organization_avatar_url} name={offer.organization_name} size="sm" />
      <div class="min-w-0 flex-1">
        <h3 class="font-h4 text-h4 line-clamp-2 text-on-surface">{offer.title}</h3>
        <p class="text-label-md font-label-md truncate text-on-surface-variant">
          {offer.organization_name}
        </p>
      </div>
      <Badge status={offer.status}>{OFFER_STATUS_LABEL[offer.status]}</Badge>
    </div>
    <div class="mt-xs flex flex-wrap items-center gap-md text-on-surface-variant">
      <span class="inline-flex items-center gap-1">
        <Icon name={offer.is_remote ? 'wifi' : 'location_on'} size={16} />
        <span class="text-body-md font-body-md">{locationText}</span>
      </span>
      <span class="inline-flex items-center gap-1">
        <Icon name="schedule" size={16} />
        <span class="text-body-md font-body-md">{scheduleText}</span>
      </span>
    </div>
  </div>
</svelte:element>

<script lang="ts">
  // Live preview sidebar shown while creating/editing an offer.
  // Renders the same media+content scaffold as SwipeCard but in a static, smaller frame.
  import Icon from '$lib/components/ui/Icon.svelte';
  import OrgLogo from '$lib/components/ui/OrgLogo.svelte';
  import OfferMediaHeader from './OfferMediaHeader.svelte';

  interface PreviewOffer {
    title?: string;
    description?: string;
    organization_name?: string;
    organization_avatar_url?: string | null;
    organization_rating?: number | null;
    cover_image_url?: string | null;
    is_remote?: boolean;
    city?: string | null;
    starts_at?: string | null;
  }

  interface Props {
    offer: PreviewOffer;
    class?: string;
  }
  const { offer, class: klass = '' }: Props = $props();

  const title = $derived(offer.title || 'Titel des Angebots');
  const description = $derived(offer.description || 'Beschreibung erscheint hier.');
  const orgName = $derived(offer.organization_name || 'Deine Organisation');
  const location = $derived(
    offer.is_remote ? 'Digital / Remote' : (offer.city || 'Ort folgt')
  );
  const schedule = $derived(
    offer.starts_at
      ? new Date(offer.starts_at).toLocaleString('de-DE', {
          weekday: 'short',
          day: '2-digit',
          month: 'short',
          hour: '2-digit',
          minute: '2-digit'
        })
      : 'Flexibel'
  );
</script>

<aside
  class="overflow-hidden rounded-3xl border border-surface-container-high bg-surface-container-lowest shadow-[0px_8px_30px_rgba(47,79,79,0.12)] {klass}"
  aria-label="Vorschau"
>
  <OfferMediaHeader
    cover_image_url={offer.cover_image_url}
    organization_rating={offer.organization_rating}
    heightClass="h-40"
  />
  <div class="relative p-md">
    <div class="absolute -top-6 left-md">
      <OrgLogo src={offer.organization_avatar_url} name={orgName} size="md" />
    </div>
    <div class="mt-sm">
      <h3 class="font-h4 text-h4 mb-xs text-on-surface line-clamp-2">{title}</h3>
      <p class="font-label-md text-label-md mb-sm text-on-surface-variant">{orgName}</p>
      <div class="mb-sm flex flex-col gap-1 text-on-surface-variant">
        <div class="flex items-center gap-sm">
          <Icon name={offer.is_remote ? 'wifi' : 'location_on'} size={18} />
          <span class="font-body-md text-body-md">{location}</span>
        </div>
        <div class="flex items-center gap-sm">
          <Icon name="schedule" size={18} />
          <span class="font-body-md text-body-md">{schedule}</span>
        </div>
      </div>
      <p class="font-body-md text-body-md text-on-surface line-clamp-4">{description}</p>
    </div>
  </div>
</aside>

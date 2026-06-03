<script lang="ts">
  // Compact row for a helper's own application list.
  import type { ApplicationRow, OfferRow } from '$lib/types/database';
  import Badge from '$lib/components/ui/Badge.svelte';
  import { APPLICATION_STATUS_LABEL } from '$lib/utils/labels';
  import { formatDate } from '$lib/utils/format';

  interface Props {
    application: ApplicationRow;
    offer: Pick<OfferRow, 'id' | 'title' | 'city' | 'is_remote' | 'starts_at'>;
    href?: string;
    onclick?: () => void;
    class?: string;
  }
  const { application, offer, href, onclick, class: klass = '' }: Props = $props();
</script>

{#if href}
  <a
    {href}
    onclick={onclick}
    class="flex w-full items-center justify-between gap-sm rounded-xl border border-outline-variant bg-surface-container-lowest p-md text-left transition-colors hover:bg-surface-container-low {klass}"
  >
    <div class="min-w-0 flex-1">
      <h4 class="font-label-md text-label-md truncate text-on-surface">{offer.title}</h4>
      <p class="text-[12px] text-on-surface-variant">
        {offer.is_remote ? 'Remote' : (offer.city ?? '')}
        {#if offer.starts_at} · {formatDate(offer.starts_at)}{/if}
      </p>
    </div>
    <Badge status={application.status}>{APPLICATION_STATUS_LABEL[application.status]}</Badge>
  </a>
{:else}
  <button
    type="button"
    onclick={onclick}
    class="flex w-full items-center justify-between gap-sm rounded-xl border border-outline-variant bg-surface-container-lowest p-md text-left transition-colors hover:bg-surface-container-low {klass}"
  >
    <div class="min-w-0 flex-1">
      <h4 class="font-label-md text-label-md truncate text-on-surface">{offer.title}</h4>
      <p class="text-[12px] text-on-surface-variant">
        {offer.is_remote ? 'Remote' : (offer.city ?? '')}
        {#if offer.starts_at} · {formatDate(offer.starts_at)}{/if}
      </p>
    </div>
    <Badge status={application.status}>{APPLICATION_STATUS_LABEL[application.status]}</Badge>
  </button>
{/if}

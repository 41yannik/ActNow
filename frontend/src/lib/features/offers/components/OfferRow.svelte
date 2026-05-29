<script lang="ts">
  // Dashboard table row for an org's own offers.
  import type { OfferRow as OfferRowType } from '$lib/types/database';
  import Badge from '$lib/components/ui/Badge.svelte';
  import Dropdown from '$lib/components/ui/Dropdown.svelte';
  import DropdownItem from '$lib/components/ui/DropdownItem.svelte';
  import { formatDate } from '$lib/utils/format';
  import { OFFER_STATUS_LABEL } from '$lib/utils/labels';

  interface Props {
    offer: OfferRowType;
    href?: string;
    onedit?: (offerId: string) => void;
    onpublish?: (offerId: string) => void;
    onview_applications?: (offerId: string) => void;
    ondelete?: (offerId: string) => void;
  }
  const { offer, href, onedit, onpublish, onview_applications, ondelete }: Props = $props();

  const applicationsLabel = $derived(
    offer.max_helpers
      ? `${offer.accepted_helpers_count} / ${offer.max_helpers}`
      : `${offer.accepted_helpers_count}`
  );
</script>

<tr class="border-b border-outline-variant/40 hover:bg-surface-container-low">
  <td class="px-md py-sm">
    {#if href}
      <a class="font-label-md text-label-md text-primary hover:underline" {href}>{offer.title}</a>
    {:else}
      <span class="font-label-md text-label-md text-on-surface">{offer.title}</span>
    {/if}
    {#if offer.city || offer.is_remote}
      <p class="text-[12px] text-on-surface-variant">
        {offer.is_remote ? 'Remote' : (offer.city ?? '')}
      </p>
    {/if}
  </td>
  <td class="px-md py-sm text-on-surface-variant">{applicationsLabel}</td>
  <td class="px-md py-sm text-on-surface-variant">
    {offer.starts_at ? formatDate(offer.starts_at) : '—'}
  </td>
  <td class="px-md py-sm">
    <Badge status={offer.status}>{OFFER_STATUS_LABEL[offer.status]}</Badge>
  </td>
  <td class="px-md py-sm text-right">
    <Dropdown>
      {#snippet children(close)}
        <DropdownItem
          icon="edit"
          label="Bearbeiten"
          onclick={() => {
            onedit?.(offer.id);
            close();
          }}
        />
        <DropdownItem
          icon="group"
          label="Bewerbungen"
          onclick={() => {
            onview_applications?.(offer.id);
            close();
          }}
        />
        {#if offer.status === 'draft' || offer.status === 'paused'}
          <DropdownItem
            icon="publish"
            label="Veröffentlichen"
            onclick={() => {
              onpublish?.(offer.id);
              close();
            }}
          />
        {/if}
        <DropdownItem
          icon="delete"
          label="Löschen"
          danger
          onclick={() => {
            ondelete?.(offer.id);
            close();
          }}
        />
      {/snippet}
    </Dropdown>
  </td>
</tr>

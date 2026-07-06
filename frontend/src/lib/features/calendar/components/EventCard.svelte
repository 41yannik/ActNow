<script lang="ts">
  // Card representing a single accepted application / event.
  import Icon from '$lib/components/ui/Icon.svelte';
  import Badge from '$lib/components/ui/Badge.svelte';
  import { formatDateTime } from '$lib/utils/format';

  interface Props {
    title: string;
    organizationName?: string;
    startsAt: string;
    endsAt?: string | null;
    location?: string | null;
    isRemote?: boolean;
    statusLabel?: string;
    href?: string;
    class?: string;
  }
  const {
    title,
    organizationName,
    startsAt,
    endsAt = null,
    location = null,
    isRemote = false,
    statusLabel,
    href,
    class: klass = '',
  }: Props = $props();
</script>

<svelte:element
  this={href ? 'a' : 'article'}
  {href}
  class="block rounded-2xl border border-outline-variant bg-surface-container-lowest p-md transition-colors hover:bg-surface-container-low {klass}"
>
  <div class="flex items-start justify-between gap-sm">
    <div class="min-w-0">
      <h3 class="font-label-md text-label-md text-on-surface">{title}</h3>
      {#if organizationName}
        <p class="text-[12px] text-on-surface-variant">{organizationName}</p>
      {/if}
    </div>
    {#if statusLabel}
      <Badge tone="info">{statusLabel}</Badge>
    {/if}
  </div>
  <div class="mt-xs flex flex-col gap-1 text-[13px] text-on-surface-variant">
    <span class="inline-flex items-center gap-1">
      <Icon name="schedule" size={16} />
      {formatDateTime(startsAt)}{endsAt ? ` – ${formatDateTime(endsAt)}` : ''}
    </span>
    {#if location || isRemote}
      <span class="inline-flex items-center gap-1">
        <Icon name={isRemote ? 'wifi' : 'location_on'} size={16} />
        {isRemote ? 'Remote' : location}
      </span>
    {/if}
  </div>
</svelte:element>

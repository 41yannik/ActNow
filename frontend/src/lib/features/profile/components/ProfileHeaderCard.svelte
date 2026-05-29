<script lang="ts">
  // Profile header showing avatar, name, role-related meta, and an optional edit action.
  import Avatar from '$lib/components/ui/Avatar.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import RatingStars from '$lib/components/ui/RatingStars.svelte';
  import type { Snippet } from 'svelte';

  interface Props {
    name: string;
    avatarUrl?: string | null;
    subtitle?: string | null;
    city?: string | null;
    averageRating?: number | null;
    ratingCount?: number | null;
    onedit?: () => void;
    actions?: Snippet;
    class?: string;
  }
  const {
    name,
    avatarUrl = null,
    subtitle = null,
    city = null,
    averageRating = null,
    ratingCount = null,
    onedit,
    actions,
    class: klass = ''
  }: Props = $props();
</script>

<header
  class="flex flex-col gap-md rounded-3xl bg-surface-container-low p-md sm:flex-row sm:items-center {klass}"
>
  <Avatar src={avatarUrl} name={name} size="xl" />
  <div class="min-w-0 flex-1">
    <h1 class="font-h2 text-h2 truncate text-on-surface">{name}</h1>
    {#if subtitle}
      <p class="text-body-md font-body-md text-on-surface-variant">{subtitle}</p>
    {/if}
    <div class="mt-xs flex flex-wrap items-center gap-md text-on-surface-variant">
      {#if city}
        <span class="text-label-md font-label-md">{city}</span>
      {/if}
      {#if averageRating != null && averageRating > 0}
        <RatingStars value={averageRating} count={ratingCount ?? null} showValue />
      {/if}
    </div>
  </div>
  <div class="flex items-center gap-xs">
    {#if actions}{@render actions()}{/if}
    {#if onedit}
      <Button variant="outlined" leadingIcon="edit" onclick={onedit}>Bearbeiten</Button>
    {/if}
  </div>
</header>

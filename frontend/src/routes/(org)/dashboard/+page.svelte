<script lang="ts">
  import { onMount } from 'svelte';
  import PageHeader from '$lib/components/layout/PageHeader.svelte';
  import MetricCard from '$lib/features/dashboard/components/MetricCard.svelte';
  import ActivityFeed from '$lib/features/dashboard/components/ActivityFeed.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import { getOrgDashboardMetrics } from '$lib/services/supabase/dashboard';
  import { listOrgOffers } from '$lib/services/supabase/offers';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { formatRelative } from '$lib/utils/format';
  import { OFFER_STATUS_LABEL } from '$lib/utils/labels';

  let loading = $state(true);
  let metrics = $state({
    open_offers: 0,
    new_applications: 0,
    upcoming_engagements: 0,
    unread_messages: 0,
  });
  let recentOffers = $state<any[]>([]);

  async function load() {
    if (!auth.profile) return;
    loading = true;
    try {
      const [m, offers] = await Promise.all([
        getOrgDashboardMetrics(auth.profile.id),
        listOrgOffers(auth.profile.id),
      ]);
      metrics = m;
      recentOffers = offers.slice(0, 5);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Dashboard nicht laden');
    } finally {
      loading = false;
    }
  }

  onMount(load);
</script>

<svelte:head><title>Dashboard · ActNow</title></svelte:head>

<section class="flex flex-col gap-md p-md">
  <PageHeader title="Dashboard" subtitle={`Willkommen, ${auth.profile?.display_name ?? ''}`}>
    {#snippet action()}
      <Button leadingIcon="add" onclick={() => (location.href = '/offers/new')}
        >Neues Angebot</Button
      >
    {/snippet}
  </PageHeader>

  {#if loading}
    <div class="flex justify-center py-lg"><LoadingSpinner /></div>
  {:else}
    <div class="grid grid-cols-2 gap-sm md:grid-cols-4">
      <MetricCard
        icon="campaign"
        label="Offene Angebote"
        value={metrics.open_offers}
        onclick={() => (location.href = '/offers')}
      />
      <MetricCard
        icon="how_to_reg"
        label="Neue Bewerbungen"
        value={metrics.new_applications}
        onclick={() => (location.href = '/applications')}
      />
      <MetricCard
        icon="event_available"
        label="Kommende Einsätze"
        value={metrics.upcoming_engagements}
      />
      <MetricCard
        icon="mark_email_unread"
        label="Ungelesen"
        value={metrics.unread_messages}
        onclick={() => (location.href = '/messages')}
      />
    </div>

    <ActivityFeed
      title="Aktuelle Angebote"
      icon="campaign"
      items={recentOffers.map((o) => ({
        id: o.id,
        title: o.title,
        subtitle: OFFER_STATUS_LABEL[o.status as keyof typeof OFFER_STATUS_LABEL],
        timestamp: formatRelative(o.updated_at),
        href: `/offers/${o.id}/edit`,
      }))}
    />
  {/if}
</section>

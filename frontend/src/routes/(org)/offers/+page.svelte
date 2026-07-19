<script lang="ts">
  import { onMount } from 'svelte';
  import PageHeader from '$lib/components/layout/PageHeader.svelte';
  import OfferRow from '$lib/features/offers/components/OfferRow.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import { listOrgOffers } from '$lib/demo/repository';
  import { showDemoAction } from '$lib/demo/actions';
  import { demoSession as auth } from '$lib/demo/session.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { goto } from '$app/navigation';
  import type { OfferRow as OfferRowType } from '$lib/types/database';

  let loading = $state(true);
  let offers = $state<OfferRowType[]>([]);

  async function load() {
    if (!auth.profile) return;
    loading = true;
    try {
      offers = await listOrgOffers(auth.profile.id);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Angebote nicht laden');
    } finally {
      loading = false;
    }
  }

  onMount(load);
</script>

<svelte:head><title>Angebote · ActNow</title></svelte:head>

<section class="flex flex-col gap-md p-md">
  <PageHeader title="Angebote">
    {#snippet action()}
      <Button leadingIcon="add" onclick={() => goto('/offers/new')}>Neues Angebot</Button>
    {/snippet}
  </PageHeader>

  {#if loading}
    <div class="flex justify-center py-lg"><LoadingSpinner /></div>
  {:else if offers.length === 0}
    <EmptyState
      icon="campaign"
      title="Noch keine Angebote"
      description="Erstelle dein erstes Angebot."
    >
      {#snippet action()}
        <Button leadingIcon="add" onclick={() => goto('/offers/new')}>Neues Angebot</Button>
      {/snippet}
    </EmptyState>
  {:else}
    <div
      class="overflow-x-auto rounded-2xl border border-outline-variant bg-surface-container-lowest"
    >
      <table class="w-full text-left text-body-md">
        <thead
          class="border-b border-outline-variant bg-surface-container-low text-label-md font-label-md text-on-surface-variant"
        >
          <tr>
            <th class="px-md py-sm">Titel</th>
            <th class="px-md py-sm">Helfer</th>
            <th class="px-md py-sm">Datum</th>
            <th class="px-md py-sm">Status</th>
            <th class="px-md py-sm"></th>
          </tr>
        </thead>
        <tbody>
          {#each offers as o (o.id)}
            <OfferRow
              offer={o}
              onedit={() => showDemoAction('Angebot bearbeiten')}
              onview_applications={(id) => goto(`/offers/${id}/applications`)}
              onpublish={() => showDemoAction('Angebot veröffentlichen')}
              ondelete={() => showDemoAction('Angebot löschen')}
            />
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</section>

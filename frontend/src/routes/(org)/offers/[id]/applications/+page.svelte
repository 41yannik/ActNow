<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/state';
  import PageHeader from '$lib/components/layout/PageHeader.svelte';
  import ApplicantCard from '$lib/features/applications/components/ApplicantCard.svelte';
  import StatusFilterBar from '$lib/features/applications/components/StatusFilterBar.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import {
    listApplicationsForOffer,
    getHelperProfiles,
    getOffer,
    getProfiles,
  } from '$lib/demo/repository';
  import { showDemoAction } from '$lib/demo/actions';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { goto } from '$app/navigation';
  import type { ApplicationStatus, ApplicationRow, OfferRow } from '$lib/types/database';
  import type { ApplicantView } from '$lib/features/applications/components/ApplicantCard.svelte';

  let loading = $state(true);
  let offer = $state<OfferRow | null>(null);
  let applicants = $state<ApplicantView[]>([]);
  let filter = $state<ApplicationStatus | 'all'>('all');

  const offerId = $derived(page.params.id as string);

  async function load() {
    loading = true;
    try {
      offer = await getOffer(offerId);
      const apps = (await listApplicationsForOffer(offerId)) as ApplicationRow[];
      const ids = [...new Set(apps.map((a) => a.helper_profile_id))];
      if (!ids.length) {
        applicants = [];
        return;
      }
      const [profiles, helpers] = await Promise.all([getProfiles(ids), getHelperProfiles(ids)]);
      const profileMap = new Map(profiles.map((profile) => [profile.id, profile]));
      const helperMap = new Map(helpers.map((helper) => [helper.profile_id, helper]));
      applicants = apps.map((a) => ({
        application: a,
        profile: profileMap.get(a.helper_profile_id)!,
        helper: helperMap.get(a.helper_profile_id) ?? null,
      }));
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Bewerbungen nicht laden');
    } finally {
      loading = false;
    }
  }

  onMount(load);

  const filtered = $derived(
    filter === 'all' ? applicants : applicants.filter((a) => a.application.status === filter),
  );
</script>

<svelte:head><title>Bewerbungen · ActNow</title></svelte:head>

<section class="flex flex-col gap-md p-md">
  <PageHeader title={offer?.title ?? 'Bewerbungen'} subtitle={`${applicants.length} Bewerbungen`} />

  {#if loading}
    <div class="flex justify-center py-lg"><LoadingSpinner /></div>
  {:else if !offer}
    <EmptyState
      icon="search_off"
      title="Angebot nicht gefunden"
      description="Diese Kennung gehört zu keinem Angebot der statischen Demo."
    >
      {#snippet action()}
        <Button onclick={() => goto('/offers')} leadingIcon="arrow_back">Zu den Angeboten</Button>
      {/snippet}
    </EmptyState>
  {:else}
    <StatusFilterBar value={filter} onchange={(v) => (filter = v)} />

    {#if filtered.length === 0}
      <EmptyState
        icon="how_to_reg"
        title="Keine Bewerbungen"
        description="Noch hat sich niemand beworben."
      />
    {:else}
      <div class="grid grid-cols-1 gap-sm md:grid-cols-2">
        {#each filtered as a (a.application.id)}
          <ApplicantCard
            applicant={a}
            onaccept={() => showDemoAction('Bewerbung annehmen')}
            onreject={() => showDemoAction('Bewerbung ablehnen')}
            oncomplete={() => showDemoAction('Einsatz abschließen')}
            onmessage={() => showDemoAction('Nachricht senden')}
            onview={() => showDemoAction('Bewerberprofil öffnen')}
          />
        {/each}
      </div>
    {/if}
  {/if}
</section>

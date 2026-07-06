<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/state';
  import PageHeader from '$lib/components/layout/PageHeader.svelte';
  import ApplicantCard from '$lib/features/applications/components/ApplicantCard.svelte';
  import StatusFilterBar from '$lib/features/applications/components/StatusFilterBar.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import {
    listApplicationsForOffer,
    acceptApplication,
    rejectApplication,
  } from '$lib/services/supabase/applications';
  import { getOffer } from '$lib/services/supabase/offers';
  import { supabase } from '$lib/services/supabase/client';
  import { toasts } from '$lib/stores/toasts.svelte';
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
      const { data: profiles, error } = await supabase
        .from('profiles')
        .select('id, display_name, avatar_url, city, average_rating')
        .in('id', ids);
      if (error) throw error;
      const { data: helpers } = await supabase
        .from('helper_profiles')
        .select('profile_id, skills, languages')
        .in('profile_id', ids);
      const profileMap = new Map<string, any>((profiles ?? []).map((p: any) => [p.id, p]));
      const helperMap = new Map<string, any>((helpers ?? []).map((h: any) => [h.profile_id, h]));
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

  <StatusFilterBar value={filter} onchange={(v) => (filter = v)} />

  {#if loading}
    <div class="flex justify-center py-lg"><LoadingSpinner /></div>
  {:else if filtered.length === 0}
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
          onaccept={async (id) => {
            try {
              await acceptApplication(id);
              toasts.success('Bewerbung angenommen');
              await load();
            } catch (err) {
              toasts.error(err instanceof Error ? err.message : 'Annehmen fehlgeschlagen');
            }
          }}
          onreject={async (id) => {
            try {
              await rejectApplication(id);
              toasts.success('Bewerbung abgelehnt');
              await load();
            } catch (err) {
              toasts.error(err instanceof Error ? err.message : 'Ablehnen fehlgeschlagen');
            }
          }}
        />
      {/each}
    </div>
  {/if}
</section>

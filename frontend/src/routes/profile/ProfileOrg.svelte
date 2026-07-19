<script lang="ts">
  import { onMount } from 'svelte';
  import ProfileHeaderCard from '$lib/features/profile/components/ProfileHeaderCard.svelte';
  import EditableField from '$lib/features/profile/components/EditableField.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import { getOrganizationProfile } from '$lib/demo/repository';
  import { showDemoAction } from '$lib/demo/actions';
  import { demoSession as auth } from '$lib/demo/session.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import type { OrganizationProfileRow } from '$lib/types/database';

  let loading = $state(true);
  let org = $state<OrganizationProfileRow | null>(null);

  async function load() {
    if (!auth.profile) return;
    loading = true;
    try {
      org = await getOrganizationProfile(auth.profile.id);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Profil nicht laden');
    } finally {
      loading = false;
    }
  }

  onMount(load);

  async function saveBio(next: string) {
    if (!auth.profile) return;
    void next;
    showDemoAction('Profil bearbeiten');
  }
  async function saveCity(next: string) {
    if (!auth.profile) return;
    void next;
    showDemoAction('Profil bearbeiten');
  }
</script>

<svelte:head><title>Profil · ActNow</title></svelte:head>

<section class="mx-auto flex w-full max-w-3xl flex-col gap-md p-md">
  {#if loading || !auth.profile}
    <div class="flex justify-center py-lg"><LoadingSpinner /></div>
  {:else}
    <ProfileHeaderCard
      name={auth.profile.display_name}
      avatarUrl={auth.profile.avatar_url}
      subtitle={org?.legal_name ?? null}
      city={auth.profile.city}
      averageRating={auth.profile.average_rating}
      ratingCount={auth.profile.rating_count}
      onedit={() => showDemoAction('Profil bearbeiten')}
    />

    <EditableField
      label="Über uns"
      value={auth.profile.bio ?? ''}
      multiline
      placeholder="Beschreibe deine Organisation…"
      onsave={saveBio}
    />
    <EditableField
      label="Stadt"
      value={auth.profile.city ?? ''}
      placeholder="z. B. Berlin"
      onsave={saveCity}
    />
  {/if}
</section>

<script lang="ts">
  import { onMount } from 'svelte';
  import ProfileHeaderCard from '$lib/features/profile/components/ProfileHeaderCard.svelte';
  import EditableField from '$lib/features/profile/components/EditableField.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import {
    getOrganizationProfile,
    updateOwnProfile
  } from '$lib/services/supabase/profiles';
  import { signOut } from '$lib/services/supabase/auth';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { goto } from '$app/navigation';
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
    await updateOwnProfile(auth.profile.id, { bio: next });
    await auth.refresh();
    toasts.success('Profil aktualisiert');
  }
  async function saveCity(next: string) {
    if (!auth.profile) return;
    await updateOwnProfile(auth.profile.id, { city: next });
    await auth.refresh();
    toasts.success('Profil aktualisiert');
  }
  async function logout() {
    await signOut();
    await goto('/login');
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
    >
      {#snippet actions()}
        <Button variant="outlined" leadingIcon="logout" onclick={logout}>Abmelden</Button>
      {/snippet}
    </ProfileHeaderCard>

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

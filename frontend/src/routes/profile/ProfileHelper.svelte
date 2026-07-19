<script lang="ts">
  import { onMount } from 'svelte';
  import ProfileHeaderCard from '$lib/features/profile/components/ProfileHeaderCard.svelte';
  import EditableField from '$lib/features/profile/components/EditableField.svelte';
  import StatCard from '$lib/features/profile/components/StatCard.svelte';
  import DocumentItem from '$lib/features/profile/components/DocumentItem.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import Tag from '$lib/components/ui/Tag.svelte';
  import { getHelperProfile, listHelperDocuments } from '$lib/demo/repository';
  import { showDemoAction } from '$lib/demo/actions';
  import { demoSession as auth } from '$lib/demo/session.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import type { HelperProfileRow, HelperDocumentRow } from '$lib/types/database';

  let loading = $state(true);
  let helper = $state<HelperProfileRow | null>(null);
  let docs = $state<HelperDocumentRow[]>([]);

  async function load() {
    if (!auth.profile) return;
    loading = true;
    try {
      helper = await getHelperProfile(auth.profile.id);
      docs = await listHelperDocuments(auth.profile.id);
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
      city={auth.profile.city}
      averageRating={auth.profile.average_rating}
      ratingCount={auth.profile.rating_count}
      onedit={() => showDemoAction('Profil bearbeiten')}
    />

    <div class="grid grid-cols-2 gap-sm sm:grid-cols-3">
      <StatCard
        icon="star"
        label="Bewertung"
        value={auth.profile.average_rating?.toFixed(1) ?? '—'}
        sublabel={`${auth.profile.rating_count} Bewertungen`}
      />
      <StatCard icon="check_circle" label="Einsätze" value={0} />
      <StatCard icon="schedule" label="Stunden" value={0} />
    </div>

    <EditableField
      label="Über mich"
      value={auth.profile.bio ?? ''}
      multiline
      placeholder="Erzähle etwas über dich…"
      onsave={saveBio}
    />
    <EditableField
      label="Stadt"
      value={auth.profile.city ?? ''}
      placeholder="z. B. Berlin"
      onsave={saveCity}
    />

    {#if helper && helper.skills.length}
      <div>
        <h3 class="font-h4 text-h4 mb-sm text-on-surface">Skills</h3>
        <div class="flex flex-wrap gap-1">
          {#each helper.skills as s}
            <Tag label={s} />
          {/each}
        </div>
      </div>
    {/if}

    <div>
      <h3 class="font-h4 text-h4 mb-sm text-on-surface">Dokumente</h3>
      {#if docs.length === 0}
        <EmptyState
          icon="upload_file"
          title="Keine Dokumente"
          description="Lade Nachweise hoch, wenn ein Angebot dies erfordert."
        />
      {:else}
        <div class="flex flex-col gap-xs">
          {#each docs as d (d.id)}
            <DocumentItem document={d} ondelete={() => showDemoAction('Dokument löschen')} />
          {/each}
        </div>
      {/if}
    </div>
  {/if}
</section>

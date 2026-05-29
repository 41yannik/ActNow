<script lang="ts">
  import { onMount } from 'svelte';
  import ConversationListItem from '$lib/features/chat/components/ConversationListItem.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import PageHeader from '$lib/components/layout/PageHeader.svelte';
  import { listConversationsForProfile } from '$lib/services/supabase/messages';
  import { supabase } from '$lib/services/supabase/client';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import type { ConversationRow, ProfileRow } from '$lib/types/database';

  interface Row {
    conv: ConversationRow;
    counterparty: Pick<ProfileRow, 'id' | 'display_name' | 'avatar_url'>;
  }

  let loading = $state(true);
  let rows = $state<Row[]>([]);

  async function load() {
    if (!auth.profile) return;
    loading = true;
    try {
      const convs = await listConversationsForProfile(auth.profile.id);
      const otherIds = convs.map((c) =>
        c.helper_profile_id === auth.profile!.id ? c.organization_profile_id : c.helper_profile_id
      );
      const { data: profiles, error } = await supabase
        .from('profiles')
        .select('id, display_name, avatar_url')
        .in('id', otherIds);
      if (error) throw error;
      const byId = new Map<string, any>((profiles ?? []).map((p: any) => [p.id, p]));
      rows = convs.map((c) => ({
        conv: c,
        counterparty: byId.get(
          c.helper_profile_id === auth.profile!.id ? c.organization_profile_id : c.helper_profile_id
        ) ?? { id: '', display_name: 'Unbekannt', avatar_url: null }
      }));
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Nachrichten nicht laden');
    } finally {
      loading = false;
    }
  }

  onMount(load);
</script>

<svelte:head><title>Nachrichten · ActNow</title></svelte:head>

<section class="mx-auto flex w-full max-w-2xl flex-col gap-md p-md">
  <PageHeader title="Nachrichten" />
  {#if loading}
    <div class="flex justify-center py-lg"><LoadingSpinner /></div>
  {:else if rows.length === 0}
    <EmptyState icon="chat_bubble_outline" title="Noch keine Nachrichten" />
  {:else}
    <ul class="flex flex-col gap-1">
      {#each rows as r (r.conv.id)}
        <li>
          <ConversationListItem
            conversation={r.conv}
            counterparty={r.counterparty}
            href={`/messages/${r.conv.id}`}
          />
        </li>
      {/each}
    </ul>
  {/if}
</section>

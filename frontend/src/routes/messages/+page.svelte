<script lang="ts">
  import { onMount } from 'svelte';
  import ConversationListItem from '$lib/features/chat/components/ConversationListItem.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import PageHeader from '$lib/components/layout/PageHeader.svelte';
  import { listCommunityConversations } from '$lib/demo/repository';
  import { demoSession } from '$lib/demo/session.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import type { CommunityConversationRow, ConversationRow } from '$lib/types/database';

  let loading = $state(true);
  let rows = $state<CommunityConversationRow[]>([]);

  function asConversation(row: CommunityConversationRow): ConversationRow {
    return {
      id: row.conversation_id,
      application_id: row.application_id,
      offer_id: row.offer_id,
      helper_profile_id: row.helper_profile_id,
      organization_profile_id: row.organization_profile_id,
      last_message_at: row.last_message_at,
      created_at: row.created_at,
      updated_at: row.updated_at,
    };
  }

  function preview(row: CommunityConversationRow) {
    return row.last_message_body
      ? `${row.offer_title} · ${row.last_message_body}`
      : `${row.offer_title} · Noch keine Nachricht`;
  }

  async function load() {
    loading = true;
    try {
      rows = await listCommunityConversations(demoSession.profile.id, 50);
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
      {#each rows as row (row.conversation_id)}
        <li>
          <ConversationListItem
            conversation={asConversation(row)}
            counterparty={{
              display_name: row.counterparty_display_name,
              avatar_url: row.counterparty_avatar_url,
            }}
            lastMessage={preview(row)}
            unread={row.unread_count > 0}
            href={`/messages/${row.conversation_id}`}
          />
        </li>
      {/each}
    </ul>
  {/if}
</section>

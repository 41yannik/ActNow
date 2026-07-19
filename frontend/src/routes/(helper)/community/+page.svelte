<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import SageHeader from '$lib/components/layout/SageHeader.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Icon from '$lib/components/ui/Icon.svelte';
  import ConversationListItem from '$lib/features/chat/components/ConversationListItem.svelte';
  import {
    getCommunitySummary,
    listCommunityConversations,
    listNotifications,
  } from '$lib/demo/repository';
  import { showDemoAction } from '$lib/demo/actions';
  import { formatRelative } from '$lib/utils/format';
  import { demoSession as auth } from '$lib/demo/session.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import type {
    CommunityConversationRow,
    CommunitySummary,
    ConversationRow,
    NotificationRow,
  } from '$lib/types/database';

  type Tab = 'chats' | 'activity';

  let tab = $state<Tab>('chats');
  let loadingChats = $state(true);
  let loadingActivity = $state(true);
  let chats = $state<CommunityConversationRow[]>([]);
  let notifications = $state<NotificationRow[]>([]);
  let summary = $state<CommunitySummary>({
    unread_messages: 0,
    unread_notifications: 0,
    total_unread: 0,
  });

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

  function chatPreview(row: CommunityConversationRow) {
    return row.last_message_body
      ? `${row.offer_title} · ${row.last_message_body}`
      : `${row.offer_title} · Noch keine Nachricht`;
  }

  async function loadSummary() {
    summary = await getCommunitySummary(auth.profile.id);
  }

  async function loadChats() {
    loadingChats = true;
    try {
      chats = await listCommunityConversations(auth.profile.id, 50);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Chats nicht laden');
    } finally {
      loadingChats = false;
    }
  }

  async function loadActivity() {
    loadingActivity = true;
    try {
      notifications = await listNotifications(auth.profile.id, 40);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Aktivitäten nicht laden');
    } finally {
      loadingActivity = false;
    }
  }

  async function loadAll() {
    await Promise.all([loadSummary(), loadChats(), loadActivity()]);
  }

  async function openNotification(n: NotificationRow) {
    if (n.entity_type === 'conversation' && n.entity_id) {
      await goto(`/messages/${n.entity_id}`);
      return;
    }
    showDemoAction('Aktivität als gelesen markieren');
  }

  function markAllRead() {
    showDemoAction('Aktivitäten als gelesen markieren');
  }

  onMount(() => {
    void loadAll();
  });
</script>

<svelte:head><title>Community · ActNow</title></svelte:head>

<section class="mx-auto w-full max-w-2xl">
  <SageHeader
    title="Community"
    subtitle="Chats und Aktivitäten"
    unread={summary.total_unread}
    onbell={() => (tab = 'activity')}
  />

  <div class="p-md">
    <div class="grid grid-cols-2 rounded-xl bg-surface-container p-1">
      <button
        type="button"
        onclick={() => (tab = 'chats')}
        class="flex items-center justify-center gap-2 rounded-lg px-3 py-2 text-[13px] font-semibold transition-colors
          {tab === 'chats'
          ? 'bg-surface-container-lowest text-primary shadow-sm'
          : 'text-on-surface-variant'}"
      >
        <Icon name="forum" size={16} />
        Chats
        {#if summary.unread_messages > 0}
          <span class="rounded-full bg-tertiary px-1.5 py-0.5 text-[10px] font-bold text-white">
            {summary.unread_messages}
          </span>
        {/if}
      </button>
      <button
        type="button"
        onclick={() => (tab = 'activity')}
        class="flex items-center justify-center gap-2 rounded-lg px-3 py-2 text-[13px] font-semibold transition-colors
          {tab === 'activity'
          ? 'bg-surface-container-lowest text-primary shadow-sm'
          : 'text-on-surface-variant'}"
      >
        <Icon name="notifications" size={16} />
        Aktivität
        {#if summary.unread_notifications > 0}
          <span class="rounded-full bg-tertiary px-1.5 py-0.5 text-[10px] font-bold text-white">
            {summary.unread_notifications}
          </span>
        {/if}
      </button>
    </div>

    {#if tab === 'chats'}
      <div class="mt-md">
        {#if loadingChats}
          <div class="flex justify-center py-lg"><LoadingSpinner /></div>
        {:else if chats.length === 0}
          <EmptyState icon="chat_bubble_outline" title="Noch keine Chats" />
        {:else}
          <ul class="flex flex-col gap-1">
            {#each chats as row (row.conversation_id)}
              <li>
                <ConversationListItem
                  conversation={asConversation(row)}
                  counterparty={{
                    display_name: row.counterparty_display_name,
                    avatar_url: row.counterparty_avatar_url,
                  }}
                  lastMessage={chatPreview(row)}
                  unread={row.unread_count > 0}
                  href={`/messages/${row.conversation_id}`}
                />
              </li>
            {/each}
          </ul>
        {/if}
      </div>
    {:else}
      <div class="mt-md">
        <div class="mb-sm flex items-center justify-between">
          <h2 class="font-h4 text-h4 text-on-surface">Aktivität</h2>
          {#if summary.unread_notifications > 0}
            <Button variant="text" size="sm" onclick={markAllRead}>Alle gelesen</Button>
          {/if}
        </div>

        {#if loadingActivity}
          <div class="flex justify-center py-lg"><LoadingSpinner /></div>
        {:else if notifications.length === 0}
          <EmptyState icon="notifications_none" title="Keine Aktivitäten" />
        {:else}
          <ul class="flex flex-col gap-2">
            {#each notifications as n (n.id)}
              <li>
                <button
                  type="button"
                  onclick={() => openNotification(n)}
                  class="flex w-full gap-3 rounded-xl border border-outline-variant bg-surface p-3 text-left transition-colors hover:bg-surface-container-low"
                >
                  <span
                    class="mt-0.5 flex h-9 w-9 shrink-0 items-center justify-center rounded-full
                      {n.read_at
                      ? 'bg-surface-container text-on-surface-variant'
                      : 'bg-primary text-on-primary'}"
                  >
                    <Icon name={n.type === 'message' ? 'chat_bubble' : 'notifications'} size={18} />
                  </span>
                  <span class="min-w-0 flex-1">
                    <span class="flex items-start justify-between gap-3">
                      <span class="text-[14px] font-semibold text-on-surface">{n.title}</span>
                      <span class="shrink-0 text-[12px] text-on-surface-variant"
                        >{formatRelative(n.created_at)}</span
                      >
                    </span>
                    {#if n.body}
                      <span
                        class="mt-1 line-clamp-2 block text-[13px] leading-snug text-on-surface-variant"
                      >
                        {n.body}
                      </span>
                    {/if}
                  </span>
                  {#if !n.read_at}
                    <span
                      class="mt-2 h-2 w-2 shrink-0 rounded-full bg-tertiary"
                      aria-label="Ungelesen"
                    ></span>
                  {/if}
                </button>
              </li>
            {/each}
          </ul>
        {/if}
      </div>
    {/if}
  </div>
</section>

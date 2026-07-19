<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/state';
  import ChatHeader from '$lib/features/chat/components/ChatHeader.svelte';
  import MessageBubble from '$lib/features/chat/components/MessageBubble.svelte';
  import DateSeparator from '$lib/features/chat/components/DateSeparator.svelte';
  import MessageComposer from '$lib/features/chat/components/MessageComposer.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
  import { getConversation, getProfile, listMessages } from '$lib/demo/repository';
  import { showDemoAction } from '$lib/demo/actions';
  import { demoSession as auth } from '$lib/demo/session.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import type { MessageRow, ConversationRow, ProfileRow } from '$lib/types/database';

  let loading = $state(true);
  let conversation = $state<ConversationRow | null>(null);
  let counterparty = $state<Pick<ProfileRow, 'display_name' | 'avatar_url'> | null>(null);
  let messages = $state<MessageRow[]>([]);
  let notFound = $state(false);

  const conversationId = $derived(page.params.id as string);

  async function load() {
    if (!auth.profile) return;
    loading = true;
    try {
      const c = await getConversation(conversationId);
      if (!c) {
        notFound = true;
        return;
      }
      conversation = c;
      const otherId =
        c.helper_profile_id === auth.profile.id ? c.organization_profile_id : c.helper_profile_id;
      counterparty = await getProfile(otherId);
      messages = await listMessages(conversationId);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Konversation nicht laden');
    } finally {
      loading = false;
    }
  }

  async function onSend(text: string) {
    if (!auth.profile || !conversation) return;
    void text;
    showDemoAction('Nachricht senden');
  }

  function isSameDay(a: string, b: string) {
    const ad = new Date(a);
    const bd = new Date(b);
    return (
      ad.getFullYear() === bd.getFullYear() &&
      ad.getMonth() === bd.getMonth() &&
      ad.getDate() === bd.getDate()
    );
  }

  onMount(load);
</script>

<svelte:head><title>Konversation · ActNow</title></svelte:head>

<section class="flex h-[calc(100vh-8rem)] flex-col">
  {#if loading}
    <div class="flex flex-1 items-center justify-center"><LoadingSpinner /></div>
  {:else if notFound || !counterparty}
    <div class="p-md">
      <EmptyState
        icon="search_off"
        title="Konversation nicht gefunden"
        description="Diese Unterhaltung ist in den Demo-Daten nicht vorhanden."
      />
    </div>
  {:else}
    <ChatHeader
      name={counterparty.display_name}
      avatarUrl={counterparty.avatar_url}
      onback={() => history.back()}
    />
    <div class="flex flex-1 flex-col gap-1 overflow-y-auto p-md">
      {#each messages as m, i (m.id)}
        {#if i === 0 || !isSameDay(messages[i - 1].created_at, m.created_at)}
          <DateSeparator date={m.created_at} />
        {/if}
        <MessageBubble
          body={m.body}
          createdAt={m.created_at}
          mine={m.sender_profile_id === auth.profile?.id}
          read={!!m.read_at}
        />
      {/each}
    </div>
    <MessageComposer onsend={onSend} />
  {/if}
</section>

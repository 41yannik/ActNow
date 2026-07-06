<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { page } from '$app/state';
  import ChatHeader from '$lib/features/chat/components/ChatHeader.svelte';
  import MessageBubble from '$lib/features/chat/components/MessageBubble.svelte';
  import DateSeparator from '$lib/features/chat/components/DateSeparator.svelte';
  import MessageComposer from '$lib/features/chat/components/MessageComposer.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import {
    getConversation,
    listMessages,
    markConversationRead,
    sendMessage,
  } from '$lib/services/supabase/messages';
  import { supabase } from '$lib/services/supabase/client';
  import { subscribeChanges, unsubscribe } from '$lib/utils/realtime';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import type { MessageRow, ConversationRow, ProfileRow } from '$lib/types/database';
  import type { RealtimeChannel } from '@supabase/supabase-js';

  let loading = $state(true);
  let conversation = $state<ConversationRow | null>(null);
  let counterparty = $state<Pick<ProfileRow, 'display_name' | 'avatar_url'> | null>(null);
  let messages = $state<MessageRow[]>([]);
  let channel: RealtimeChannel | null = null;

  const conversationId = $derived(page.params.id as string);

  async function load() {
    if (!auth.profile) return;
    loading = true;
    try {
      const c = await getConversation(conversationId);
      if (!c) throw new Error('Konversation nicht gefunden');
      conversation = c;
      const otherId =
        c.helper_profile_id === auth.profile.id ? c.organization_profile_id : c.helper_profile_id;
      const { data, error } = await supabase
        .from('profiles')
        .select('display_name, avatar_url')
        .eq('id', otherId)
        .single();
      if (error) throw error;
      counterparty = data;
      messages = await listMessages(conversationId);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Konversation nicht laden');
    } finally {
      loading = false;
    }
  }

  async function onSend(text: string) {
    if (!auth.profile || !conversation) return;
    try {
      const created = await sendMessage(conversation.id, auth.profile.id, text);
      if (!messages.find((m) => m.id === created.id)) {
        messages = [...messages, created];
      }
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Nachricht konnte nicht gesendet werden.');
    }
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

  onMount(async () => {
    await load();
    if (conversation) {
      try {
        await markConversationRead(conversation.id);
      } catch {
        // non-fatal; the message thread itself is still usable
      }
      channel = subscribeChanges<Record<string, unknown>>(
        `messages:${conversation.id}`,
        { table: 'messages', filter: `conversation_id=eq.${conversation.id}` },
        (payload) => {
          if (payload.eventType === 'INSERT' && payload.new) {
            const m = payload.new as unknown as MessageRow;
            if (!messages.find((x) => x.id === m.id)) {
              messages = [...messages, m];
            }
            if (auth.profile && m.sender_profile_id !== auth.profile.id) {
              void markConversationRead(conversation!.id);
            }
          }
          if (payload.eventType === 'UPDATE' && payload.new) {
            const m = payload.new as unknown as MessageRow;
            messages = messages.map((x) => (x.id === m.id ? m : x));
          }
        },
        '*',
      );
    }
  });

  onDestroy(() => {
    if (channel) void unsubscribe(channel);
  });
</script>

<svelte:head><title>Konversation · ActNow</title></svelte:head>

<section class="flex h-[calc(100vh-8rem)] flex-col">
  {#if loading || !counterparty}
    <div class="flex flex-1 items-center justify-center"><LoadingSpinner /></div>
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

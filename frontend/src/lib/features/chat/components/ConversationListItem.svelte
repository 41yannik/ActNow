<script lang="ts">
  // A single row in the conversation list (sidebar).
  import type { ConversationRow, ProfileRow } from '$lib/types/database';
  import Avatar from '$lib/components/ui/Avatar.svelte';
  import { formatRelative } from '$lib/utils/format';

  interface Props {
    conversation: ConversationRow;
    counterparty: Pick<ProfileRow, 'display_name' | 'avatar_url'>;
    lastMessage?: string | null;
    unread?: boolean;
    selected?: boolean;
    href?: string;
    onclick?: () => void;
    class?: string;
  }
  const {
    conversation,
    counterparty,
    lastMessage = null,
    unread = false,
    selected = false,
    href,
    onclick,
    class: klass = '',
  }: Props = $props();
</script>

{#if href}
  <a
    {href}
    {onclick}
    class="
      flex w-full items-center gap-sm rounded-xl px-sm py-sm text-left transition-colors
      {selected ? 'bg-secondary-container' : 'hover:bg-surface-container-low'}
      {klass}
    "
  >
    <Avatar src={counterparty.avatar_url} name={counterparty.display_name} size="md" />
    <div class="min-w-0 flex-1">
      <div class="flex items-baseline justify-between gap-sm">
        <span
          class="font-label-md text-label-md truncate {unread
            ? 'text-on-surface font-semibold'
            : 'text-on-surface'}"
        >
          {counterparty.display_name}
        </span>
        {#if conversation.last_message_at}
          <span class="shrink-0 text-[12px] text-on-surface-variant">
            {formatRelative(conversation.last_message_at)}
          </span>
        {/if}
      </div>
      {#if lastMessage}
        <p class="truncate text-[13px] {unread ? 'text-on-surface' : 'text-on-surface-variant'}">
          {lastMessage}
        </p>
      {/if}
    </div>
    {#if unread}
      <span class="ml-xs h-2 w-2 shrink-0 rounded-full bg-primary" aria-label="Ungelesen"></span>
    {/if}
  </a>
{:else}
  <button
    type="button"
    {onclick}
    class="
      flex w-full items-center gap-sm rounded-xl px-sm py-sm text-left transition-colors
      {selected ? 'bg-secondary-container' : 'hover:bg-surface-container-low'}
      {klass}
    "
  >
    <Avatar src={counterparty.avatar_url} name={counterparty.display_name} size="md" />
    <div class="min-w-0 flex-1">
      <div class="flex items-baseline justify-between gap-sm">
        <span
          class="font-label-md text-label-md truncate {unread
            ? 'text-on-surface font-semibold'
            : 'text-on-surface'}"
        >
          {counterparty.display_name}
        </span>
        {#if conversation.last_message_at}
          <span class="shrink-0 text-[12px] text-on-surface-variant">
            {formatRelative(conversation.last_message_at)}
          </span>
        {/if}
      </div>
      {#if lastMessage}
        <p class="truncate text-[13px] {unread ? 'text-on-surface' : 'text-on-surface-variant'}">
          {lastMessage}
        </p>
      {/if}
    </div>
    {#if unread}
      <span class="ml-xs h-2 w-2 shrink-0 rounded-full bg-primary" aria-label="Ungelesen"></span>
    {/if}
  </button>
{/if}

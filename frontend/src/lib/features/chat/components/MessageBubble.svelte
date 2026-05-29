<script lang="ts">
  // A chat message bubble. Side determined by `mine` prop.
  import { formatTime } from '$lib/utils/format';

  interface Props {
    body: string;
    createdAt: string;
    mine: boolean;
    read?: boolean;
    class?: string;
  }
  const { body, createdAt, mine, read = false, class: klass = '' }: Props = $props();
</script>

<div class="flex {mine ? 'justify-end' : 'justify-start'} {klass}">
  <div
    class="
      max-w-[75%] rounded-2xl px-md py-sm
      {mine
        ? 'rounded-br-md bg-primary text-on-primary'
        : 'rounded-bl-md bg-surface-container text-on-surface'}
    "
  >
    <p class="text-body-md font-body-md whitespace-pre-wrap break-words">{body}</p>
    <div
      class="mt-1 flex items-center justify-end gap-1 text-[11px] {mine ? 'text-on-primary/70' : 'text-on-surface-variant'}"
    >
      <span>{formatTime(createdAt)}</span>
      {#if mine}
        <span aria-label={read ? 'Gelesen' : 'Gesendet'}>{read ? '✓✓' : '✓'}</span>
      {/if}
    </div>
  </div>
</div>

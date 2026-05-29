<script lang="ts">
  import type { HelperDocumentRow } from '$lib/types/database';
  import Icon from '$lib/components/ui/Icon.svelte';
  import IconButton from '$lib/components/ui/IconButton.svelte';
  import Badge from '$lib/components/ui/Badge.svelte';
  import { formatDate } from '$lib/utils/format';

  interface Props {
    document: HelperDocumentRow;
    ondelete?: (id: string) => void;
    onopen?: (id: string) => void;
    class?: string;
  }
  const { document, ondelete, onopen, class: klass = '' }: Props = $props();

  const expired = $derived(
    document.expires_at ? new Date(document.expires_at).getTime() < Date.now() : false
  );
</script>

<div
  class="flex items-center gap-sm rounded-xl border border-outline-variant bg-surface-container-lowest p-sm {klass}"
>
  <Icon name="description" size={24} class="text-primary" />
  <div class="min-w-0 flex-1">
    <button type="button" class="block text-left" onclick={() => onopen?.(document.id)}>
      <p class="font-label-md text-label-md truncate text-on-surface">{document.title}</p>
    </button>
    <p class="text-[12px] text-on-surface-variant">
      {document.expires_at ? `Gültig bis ${formatDate(document.expires_at)}` : 'Unbefristet'}
    </p>
  </div>
  {#if expired}
    <Badge tone="danger">Abgelaufen</Badge>
  {/if}
  {#if ondelete}
    <IconButton icon="delete" label="Löschen" size="sm" onclick={() => ondelete(document.id)} />
  {/if}
</div>

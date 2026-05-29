<script lang="ts">
  // Header strip above the message thread.
  import Avatar from '$lib/components/ui/Avatar.svelte';
  import IconButton from '$lib/components/ui/IconButton.svelte';

  interface Props {
    name: string;
    avatarUrl?: string | null;
    subtitle?: string | null;
    onback?: () => void;
    oninfo?: () => void;
    class?: string;
  }
  const { name, avatarUrl = null, subtitle = null, onback, oninfo, class: klass = '' }: Props = $props();
</script>

<header
  class="flex items-center gap-sm border-b border-outline-variant bg-surface-container-lowest px-md py-sm {klass}"
>
  {#if onback}
    <IconButton icon="arrow_back" label="Zurück" onclick={onback} />
  {/if}
  <Avatar src={avatarUrl} name={name} size="sm" />
  <div class="min-w-0 flex-1">
    <h2 class="font-label-md text-label-md truncate text-on-surface">{name}</h2>
    {#if subtitle}
      <p class="truncate text-[12px] text-on-surface-variant">{subtitle}</p>
    {/if}
  </div>
  {#if oninfo}
    <IconButton icon="info" label="Details" onclick={oninfo} />
  {/if}
</header>

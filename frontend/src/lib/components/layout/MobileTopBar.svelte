<script lang="ts">
  import IconButton from '../ui/IconButton.svelte';

  interface Props {
    title?: string;
    onmenu?: () => void;
    /** Optional trailing slot (e.g. notification icon button). */
  }
  const { title = 'ActNow', onmenu }: Props = $props();
</script>

<header
  class="md:hidden sticky top-0 z-30 flex items-center gap-sm border-b border-outline-variant bg-surface px-sm py-2"
>
  <IconButton icon="menu" label="Menü öffnen" onclick={() => onmenu?.()} />
  <p class="font-h4 text-h4 text-on-surface">{title}</p>
</header>

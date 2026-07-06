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
  class="md:hidden sticky top-0 z-30 flex items-center gap-sm bg-primary-container bg-sage-pattern px-sm py-2.5 rounded-b-header shadow-md text-white h-[66px]"
>
  <IconButton
    icon="menu"
    label="Menü öffnen"
    onclick={() => onmenu?.()}
    class="bg-white/18 text-white hover:bg-white/30 rounded-full w-9 h-9 flex items-center justify-center border-none"
  />
  <p class="font-h4 text-h4 text-white font-bold ml-1">{title}</p>
</header>

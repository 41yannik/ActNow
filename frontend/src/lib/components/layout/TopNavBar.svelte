<script lang="ts">
  import IconButton from '../ui/IconButton.svelte';

  interface NavItem {
    label: string;
    href: string;
    active?: boolean;
  }
  interface Props {
    brand?: string;
    items?: NavItem[];
    class?: string;
  }
  let {
    brand = 'ActNow',
    items = [
      { label: 'Discover', href: '/discover', active: true },
      { label: 'Calendar', href: '/calendar' },
      { label: 'Messages', href: '/messages' }
    ],
    class: klass = ''
  }: Props = $props();
</script>

<header class="bg-primary-container bg-sage-pattern text-white sticky top-0 z-40 rounded-b-header shadow-md transition-all {klass}">
  <div class="flex justify-between items-center w-full px-md md:px-xl py-sm max-w-container-max mx-auto h-[78px]">
    <a href="/" class="font-h2 text-h2 font-bold text-white tracking-tight hover:opacity-90 transition-opacity">{brand}</a>
    <nav class="hidden md:flex gap-lg items-center">
      {#each items as item}
        <a
          href={item.href}
          class="
            font-label-md text-label-md transition-all pb-1
            {item.active
              ? 'text-white border-b-2 border-white font-semibold'
              : 'text-white/80 hover:text-white'}
          "
        >
          {item.label}
        </a>
      {/each}
    </nav>
    <div class="flex items-center gap-xs">
      <IconButton icon="search" label="Suche" class="bg-white/18 text-white hover:bg-white/30 rounded-full w-9 h-9 flex items-center justify-center border-none" />
      <IconButton icon="account_circle" label="Konto" class="hidden md:inline-flex bg-white/18 text-white hover:bg-white/30 rounded-full w-9 h-9 items-center justify-center border-none" />
    </div>
  </div>
</header>

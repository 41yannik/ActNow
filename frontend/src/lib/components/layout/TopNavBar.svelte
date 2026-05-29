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

<header class="bg-surface shadow-sm sticky top-0 z-40 {klass}">
  <div class="flex justify-between items-center w-full px-md md:px-xl py-sm max-w-container-max mx-auto">
    <a href="/" class="font-h2 text-h2 font-bold text-primary">{brand}</a>
    <nav class="hidden md:flex gap-lg items-center">
      {#each items as item}
        <a
          href={item.href}
          class="
            font-label-md text-label-md transition-colors
            {item.active
              ? 'text-primary border-b-2 border-primary pb-1'
              : 'text-on-surface-variant hover:text-primary'}
          "
        >
          {item.label}
        </a>
      {/each}
    </nav>
    <div class="flex items-center gap-xs">
      <IconButton icon="search" label="Suche" />
      <IconButton icon="account_circle" label="Konto" class="hidden md:inline-flex" />
    </div>
  </div>
</header>

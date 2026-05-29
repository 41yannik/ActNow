<script lang="ts">
  import Icon from '../ui/Icon.svelte';

  interface NavItem {
    label: string;
    href: string;
    icon: string;
    active?: boolean;
  }
  interface Props {
    items?: NavItem[];
    class?: string;
  }
  let {
    items = [
      { label: 'Discover', href: '/discover', icon: 'explore', active: true },
      { label: 'Calendar', href: '/calendar', icon: 'calendar_today' },
      { label: 'Messages', href: '/messages', icon: 'chat' },
      { label: 'Profile', href: '/profile', icon: 'person' }
    ],
    class: klass = ''
  }: Props = $props();
</script>

<nav
  class="bg-surface shadow-[0px_-4px_20px_rgba(47,79,79,0.08)] fixed bottom-0 left-0 w-full z-40
         flex justify-around items-center px-gutter py-sm md:hidden rounded-t-xl {klass}"
>
  {#each items as item}
    <a
      href={item.href}
      class="
        flex flex-col items-center justify-center rounded-full px-4 py-1 transition-transform active:scale-90
        {item.active
          ? 'bg-tertiary-fixed text-on-tertiary-fixed-variant'
          : 'text-on-surface-variant hover:bg-surface-container'}
      "
    >
      <Icon name={item.icon} filled={item.active} size={22} />
      <span class="font-label-md text-[12px] mt-0.5">{item.label}</span>
    </a>
  {/each}
</nav>

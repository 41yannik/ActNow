<script lang="ts">
  import Icon from '../ui/Icon.svelte';

  interface NavItem {
    label: string;
    href: string;
    icon: string;
    active?: boolean;
    /** Raised center button (e.g. "Start"). */
    center?: boolean;
  }
  interface Props {
    items?: NavItem[];
    class?: string;
  }
  // 5-Tab Navigation aus der Vorlage (chrome.jsx: BottomNav).
  let {
    items = [
      { label: 'Social', href: '/community', icon: 'group' },
      { label: 'Rewards', href: '/rewards', icon: 'star' },
      { label: 'Start', href: '/discover', icon: 'home', center: true },
      { label: 'Favoriten', href: '/favorites', icon: 'favorite' },
      { label: 'Profil', href: '/profile', icon: 'person' },
    ],
    class: klass = '',
  }: Props = $props();
</script>

<nav
  class="fixed bottom-0 left-0 z-40 grid w-full grid-cols-5 items-center border-t border-outline/40
         bg-white/96 px-2 pb-7 pt-2.5 backdrop-blur-md
         shadow-[0px_-4px_20px_rgba(47,79,79,0.06)] md:hidden {klass}"
>
  {#each items as item}
    <a
      href={item.href}
      class="flex flex-col items-center justify-center gap-1 py-1 transition-all active:scale-95"
      aria-current={item.active ? 'page' : undefined}
    >
      {#if item.center}
        <div
          class="-my-0.5 flex h-9 w-9 items-center justify-center rounded-full transition-colors
                 {item.active ? 'bg-primary text-white' : 'text-on-surface-variant'}"
        >
          <Icon name={item.icon} filled={item.active} size={20} />
        </div>
      {:else}
        <Icon
          name={item.icon}
          filled={item.active}
          size={22}
          class={item.active ? 'text-secondary' : 'text-on-surface-variant'}
        />
      {/if}
      <span
        class="text-[10px] tracking-wide {item.active
          ? 'font-semibold text-secondary'
          : 'font-medium text-on-surface-variant'}"
      >
        {item.label}
      </span>
    </a>
  {/each}
</nav>

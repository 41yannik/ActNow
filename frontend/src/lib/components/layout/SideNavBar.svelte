<script lang="ts">
  import Icon from '../ui/Icon.svelte';
  import Avatar from '../ui/Avatar.svelte';

  interface NavItem {
    label: string;
    href: string;
    icon: string;
    active?: boolean;
  }
  interface Props {
    brand?: string;
    subtitle?: string;
    items?: NavItem[];
    userName?: string;
    userRole?: string;
    userAvatar?: string | null;
    class?: string;
  }
  let {
    brand = 'ActNow Org',
    subtitle = 'Partner Dashboard',
    items = [
      { label: 'Dashboard', href: '/org', icon: 'dashboard', active: true },
      { label: 'Offers', href: '/org/offers', icon: 'volunteer_activism' },
      { label: 'Applications', href: '/org/applications', icon: 'assignment_ind' },
      { label: 'Messages', href: '/org/messages', icon: 'mail' },
      { label: 'Profile', href: '/org/profile', icon: 'person' }
    ],
    userName,
    userRole,
    userAvatar = null,
    class: klass = ''
  }: Props = $props();
</script>

<nav
  class="hidden md:flex flex-col bg-surface-container-low w-64 fixed left-0 top-0 h-full p-md z-30
         border-r border-outline-variant/30 {klass}"
>
  <div class="mb-lg">
    <h1 class="font-h2 text-h2 font-bold text-primary">{brand}</h1>
    <p class="font-label-md text-label-md text-on-surface-variant mt-xs">{subtitle}</p>
  </div>
  <ul class="flex-1 flex flex-col gap-sm">
    {#each items as item}
      <li>
        <a
          href={item.href}
          class="
            flex items-center gap-base px-md py-sm rounded-lg font-label-md text-label-md transition-all
            {item.active
              ? 'bg-secondary-container text-on-secondary-container translate-x-1'
              : 'text-on-surface-variant hover:bg-surface-container-highest'}
          "
        >
          <Icon name={item.icon} filled={item.active} size={22} />
          {item.label}
        </a>
      </li>
    {/each}
  </ul>
  {#if userName}
    <div class="mt-auto flex items-center gap-sm pt-md border-t border-outline-variant/30">
      <Avatar src={userAvatar} name={userName} size="md" />
      <div class="flex-1 overflow-hidden">
        <p class="font-label-md text-label-md truncate text-on-surface">{userName}</p>
        {#if userRole}
          <p class="font-body-md text-[12px] truncate text-on-surface-variant">{userRole}</p>
        {/if}
      </div>
    </div>
  {/if}
</nav>

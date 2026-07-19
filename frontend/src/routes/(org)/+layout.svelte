<script lang="ts">
  import { page } from '$app/state';
  import AppShell from '$lib/components/layout/AppShell.svelte';
  import SideNavBar from '$lib/components/layout/SideNavBar.svelte';
  import MobileTopBar from '$lib/components/layout/MobileTopBar.svelte';
  import { demoSession as auth } from '$lib/demo/session.svelte';

  let { children } = $props();
  auth.ensureRole('org');

  const path = $derived(page.url.pathname as string);
  const items = $derived([
    { label: 'Dashboard', href: '/dashboard', icon: 'dashboard', active: path === '/dashboard' },
    {
      label: 'Angebote',
      href: '/offers',
      icon: 'volunteer_activism',
      active: path.startsWith('/offers'),
    },
    {
      label: 'Bewerbungen',
      href: '/offers/offer-sommerfest/applications',
      icon: 'assignment_ind',
      active: path.includes('/applications'),
    },
    { label: 'Nachrichten', href: '/messages', icon: 'mail', active: path.startsWith('/messages') },
    { label: 'Profil', href: '/profile', icon: 'person', active: path.startsWith('/profile') },
  ]);
</script>

<AppShell docked>
  {#snippet top()}
    <MobileTopBar title={auth.profile?.display_name ?? 'ActNow'} />
  {/snippet}
  {#snippet side()}
    <SideNavBar
      brand={auth.profile?.display_name ?? 'ActNow'}
      subtitle="Organisations-Dashboard"
      {items}
      userName={auth.profile?.display_name ?? ''}
      userRole="Organisation"
      userAvatar={auth.profile?.avatar_url ?? null}
    />
  {/snippet}
  {#snippet main()}
    {@render children()}
  {/snippet}
</AppShell>

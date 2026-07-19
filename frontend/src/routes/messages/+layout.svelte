<script lang="ts">
  import { page } from '$app/state';
  import AppShell from '$lib/components/layout/AppShell.svelte';
  import TopNavBar from '$lib/components/layout/TopNavBar.svelte';
  import BottomNavBar from '$lib/components/layout/BottomNavBar.svelte';
  import SideNavBar from '$lib/components/layout/SideNavBar.svelte';
  import MobileTopBar from '$lib/components/layout/MobileTopBar.svelte';
  import Footer from '$lib/components/layout/Footer.svelte';
  import { demoSession as auth } from '$lib/demo/session.svelte';

  let { children } = $props();

  const path = $derived(page.url.pathname as string);
  const isOrg = $derived(auth.role === 'organization');

  const helperTop = $derived([
    { label: 'Discover', href: '/discover', active: false },
    { label: 'Calendar', href: '/calendar', active: false },
    { label: 'Messages', href: '/messages', active: path.startsWith('/messages') },
  ]);
  const helperBottom = $derived([
    { label: 'Discover', href: '/discover', icon: 'explore', active: false },
    { label: 'Calendar', href: '/calendar', icon: 'calendar_today', active: false },
    { label: 'Messages', href: '/messages', icon: 'chat', active: path.startsWith('/messages') },
    { label: 'Profile', href: '/profile', icon: 'person', active: false },
  ]);
  const orgItems = $derived([
    { label: 'Dashboard', href: '/dashboard', icon: 'dashboard', active: false },
    { label: 'Angebote', href: '/offers', icon: 'volunteer_activism', active: false },
    {
      label: 'Bewerbungen',
      href: '/offers/offer-sommerfest/applications',
      icon: 'assignment_ind',
      active: false,
    },
    { label: 'Nachrichten', href: '/messages', icon: 'mail', active: true },
    { label: 'Profil', href: '/profile', icon: 'person', active: false },
  ]);
</script>

{#if isOrg}
  <AppShell docked>
    {#snippet top()}
      <MobileTopBar title="Nachrichten" />
    {/snippet}
    {#snippet side()}
      <SideNavBar
        brand={auth.profile?.display_name ?? 'ActNow'}
        subtitle="Organisations-Dashboard"
        items={orgItems}
        userName={auth.profile?.display_name ?? ''}
        userRole="Organisation"
        userAvatar={auth.profile?.avatar_url ?? null}
      />
    {/snippet}
    {#snippet main()}
      {@render children()}
    {/snippet}
  </AppShell>
{:else}
  <AppShell>
    {#snippet top()}
      <TopNavBar items={helperTop} />
    {/snippet}
    {#snippet main()}
      {@render children()}
    {/snippet}
    {#snippet bottom()}
      <BottomNavBar items={helperBottom} />
    {/snippet}
    {#snippet footer()}
      <Footer class="hidden md:block" />
    {/snippet}
  </AppShell>
{/if}

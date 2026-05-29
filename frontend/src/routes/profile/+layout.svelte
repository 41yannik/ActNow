<script lang="ts">
  // Reuses messages/+layout.svelte pattern.
  import { goto } from '$app/navigation';
  import { page } from '$app/state';
  import AppShell from '$lib/components/layout/AppShell.svelte';
  import TopNavBar from '$lib/components/layout/TopNavBar.svelte';
  import BottomNavBar from '$lib/components/layout/BottomNavBar.svelte';
  import SideNavBar from '$lib/components/layout/SideNavBar.svelte';
  import MobileTopBar from '$lib/components/layout/MobileTopBar.svelte';
  import Footer from '$lib/components/layout/Footer.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import { auth } from '$lib/stores/auth.svelte';

  let { children } = $props();

  $effect(() => {
    if (auth.loading) return;
    if (!auth.isAuthenticated) {
      void goto(`/login?next=${encodeURIComponent(page.url.pathname)}`);
    }
  });

  const isOrg = $derived(auth.role === 'organization');

  const helperTop = [
    { label: 'Discover', href: '/discover', active: false },
    { label: 'Calendar', href: '/calendar', active: false },
    { label: 'Messages', href: '/messages', active: false }
  ];
  const helperBottom = [
    { label: 'Discover', href: '/discover', icon: 'explore', active: false },
    { label: 'Calendar', href: '/calendar', icon: 'calendar_today', active: false },
    { label: 'Messages', href: '/messages', icon: 'chat', active: false },
    { label: 'Profile', href: '/profile', icon: 'person', active: true }
  ];
  const orgItems = [
    { label: 'Dashboard', href: '/dashboard', icon: 'dashboard', active: false },
    { label: 'Angebote', href: '/offers', icon: 'volunteer_activism', active: false },
    { label: 'Bewerbungen', href: '/applications', icon: 'assignment_ind', active: false },
    { label: 'Nachrichten', href: '/messages', icon: 'mail', active: false },
    { label: 'Profil', href: '/profile', icon: 'person', active: true }
  ];
</script>

{#if auth.loading || !auth.isAuthenticated}
  <div class="flex min-h-screen items-center justify-center"><LoadingSpinner /></div>
{:else if isOrg}
  <AppShell docked>
    {#snippet top()}
      <MobileTopBar title="Profil" />
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

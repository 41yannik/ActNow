<script lang="ts">
  import { goto } from '$app/navigation';
  import { page } from '$app/state';
  import AppShell from '$lib/components/layout/AppShell.svelte';
  import SideNavBar from '$lib/components/layout/SideNavBar.svelte';
  import MobileTopBar from '$lib/components/layout/MobileTopBar.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import { auth } from '$lib/stores/auth.svelte';

  let { children } = $props();

  $effect(() => {
    if (auth.loading) return;
    if (!auth.isAuthenticated) {
      void goto(`/login?next=${encodeURIComponent(page.url.pathname)}`);
      return;
    }
    if (auth.role && auth.role !== 'organization' && auth.role !== 'admin') {
      void goto('/discover');
    }
  });

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
      href: '/applications',
      icon: 'assignment_ind',
      active: path.startsWith('/applications'),
    },
    { label: 'Nachrichten', href: '/messages', icon: 'mail', active: path.startsWith('/messages') },
    { label: 'Profil', href: '/profile', icon: 'person', active: path.startsWith('/profile') },
  ]);
</script>

{#if auth.loading || !auth.isAuthenticated}
  <div class="flex min-h-screen items-center justify-center">
    <LoadingSpinner />
  </div>
{:else}
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
{/if}

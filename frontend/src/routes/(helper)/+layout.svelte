<script lang="ts">
	import { goto } from '$app/navigation';
	import { page } from '$app/state';
	import AppShell from '$lib/components/layout/AppShell.svelte';
	import TopNavBar from '$lib/components/layout/TopNavBar.svelte';
	import BottomNavBar from '$lib/components/layout/BottomNavBar.svelte';
	import Footer from '$lib/components/layout/Footer.svelte';
	import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
	import { auth } from '$lib/stores/auth.svelte';

	let { children } = $props();

	$effect(() => {
		if (auth.loading) return;
		if (!auth.isAuthenticated) {
			void goto(`/login?next=${encodeURIComponent(page.url.pathname)}`);
			return;
		}
		if (auth.role && auth.role !== 'helper' && auth.role !== 'admin') {
			void goto('/dashboard');
		}
	});

	const path = $derived(page.url.pathname as string);
	const topItems = $derived([
		{ label: 'Start', href: '/discover', active: path.startsWith('/discover') },
		{ label: 'Community', href: '/community', active: path.startsWith('/community') },
		{ label: 'Bewerbungen', href: '/applications', active: path.startsWith('/applications') },
		{ label: 'Rewards', href: '/rewards', active: path.startsWith('/rewards') },
		{ label: 'Favoriten', href: '/favorites', active: path.startsWith('/favorites') },
		{ label: 'Kalender', href: '/calendar', active: path.startsWith('/calendar') }
	]);
	// 5-Tab Navigation aus der Vorlage: Social · Rewards · Start (Mitte) · Favoriten · Profil.
	const bottomItems = $derived([
		{ label: 'Social', href: '/community', icon: 'group', active: path.startsWith('/community') },
		{
			label: 'Einsätze',
			href: '/applications',
			icon: 'assignment_turned_in',
			active: path.startsWith('/applications')
		},
		{
			label: 'Start',
			href: '/discover',
			icon: 'home',
			center: true,
			active: path.startsWith('/discover')
		},
		{
			label: 'Favoriten',
			href: '/favorites',
			icon: 'favorite',
			active: path.startsWith('/favorites')
		},
		{ label: 'Profil', href: '/profile', icon: 'person', active: path.startsWith('/profile') }
	]);
</script>

{#if auth.loading || !auth.isAuthenticated}
	<div class="flex min-h-screen items-center justify-center">
		<LoadingSpinner />
	</div>
{:else}
	<AppShell>
		{#snippet top()}
			<!-- Desktop-Top-Navigation; auf Mobile übernimmt der SageHeader jeder Seite. -->
			<TopNavBar items={topItems} class="hidden md:block" />
		{/snippet}
		{#snippet main()}
			{@render children()}
		{/snippet}
		{#snippet bottom()}
			<BottomNavBar items={bottomItems} />
		{/snippet}
		{#snippet footer()}
			<Footer class="hidden md:block" />
		{/snippet}
	</AppShell>
{/if}

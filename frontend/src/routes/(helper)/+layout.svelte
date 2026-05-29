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
		{ label: 'Discover', href: '/discover', active: path.startsWith('/discover') },
		{ label: 'Calendar', href: '/calendar', active: path.startsWith('/calendar') },
		{ label: 'Messages', href: '/messages', active: path.startsWith('/messages') }
	]);
	const bottomItems = $derived([
		{
			label: 'Discover',
			href: '/discover',
			icon: 'explore',
			active: path.startsWith('/discover')
		},
		{
			label: 'Calendar',
			href: '/calendar',
			icon: 'calendar_today',
			active: path.startsWith('/calendar')
		},
		{ label: 'Messages', href: '/messages', icon: 'chat', active: path.startsWith('/messages') },
		{ label: 'Profile', href: '/profile', icon: 'person', active: path.startsWith('/profile') }
	]);
</script>

{#if auth.loading || !auth.isAuthenticated}
	<div class="flex min-h-screen items-center justify-center">
		<LoadingSpinner />
	</div>
{:else}
	<AppShell>
		{#snippet top()}
			<TopNavBar items={topItems} />
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

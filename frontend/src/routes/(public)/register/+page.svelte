<script lang="ts">
  import { goto } from '$app/navigation';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import { onMount } from 'svelte';

  onMount(() => void goto('/', { replaceState: true }));
</script>

<svelte:head><title>Demo ohne Registrierung · ActNow</title></svelte:head>
<div class="flex min-h-screen items-center justify-center"><LoadingSpinner /></div>

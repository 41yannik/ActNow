<script lang="ts">
  // Role-aware profile router. Renders helper or org variant based on auth.role.
  import HelperProfile from './ProfileHelper.svelte';
  import OrgProfile from './ProfileOrg.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import { auth } from '$lib/stores/auth.svelte';
</script>

{#if auth.loading || !auth.profile}
  <div class="flex justify-center py-lg"><LoadingSpinner /></div>
{:else if auth.role === 'organization'}
  <OrgProfile />
{:else}
  <HelperProfile />
{/if}

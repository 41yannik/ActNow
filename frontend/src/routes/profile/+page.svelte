<script lang="ts">
  // Role-aware profile router for the local portfolio demo.
  import HelperProfile from './ProfileHelper.svelte';
  import OrgProfile from './ProfileOrg.svelte';
  import { demoSession } from '$lib/demo/session.svelte';
</script>

{#if demoSession.role === 'organization'}
  <OrgProfile />
{:else}
  <HelperProfile />
{/if}

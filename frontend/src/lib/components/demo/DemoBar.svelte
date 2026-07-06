<script lang="ts">
  // Fixed top bar shown only in demo mode (portfolio showcase): labels the
  // deployment as a read-only demo and switches between the two demo roles.
  import { goto } from '$app/navigation';
  import { DEMO_MODE, DEMO_ACCOUNTS, type DemoRole } from '$lib/config/demo';
  import { auth, switchDemoRole } from '$lib/stores/auth.svelte';

  let switching = $state(false);

  const activeRole = $derived<DemoRole>(auth.role === 'organization' ? 'org' : 'helper');

  async function switchTo(role: DemoRole) {
    if (switching || role === activeRole) return;
    switching = true;
    try {
      const home = await switchDemoRole(role);
      if (home) await goto(home);
    } finally {
      switching = false;
    }
  }
</script>

{#if DEMO_MODE}
  <div
    class="sticky top-0 z-50 flex flex-wrap items-center justify-center gap-x-3 gap-y-1 border-b border-outline bg-inverse-surface px-3 py-1.5 text-inverse-on-surface"
  >
    {#if auth.demoError}
      <span class="text-label-md font-label-md">
        Demo-Backend nicht erreichbar — bitte später erneut versuchen.
      </span>
    {:else}
      <span class="text-label-md font-label-md">Demo-Modus · Portfolio-Projekt · nur Ansicht</span>
      <span class="flex items-center gap-1" role="group" aria-label="Demo-Ansicht wechseln">
        {#each Object.entries(DEMO_ACCOUNTS) as [role, account] (role)}
          <button
            type="button"
            disabled={switching}
            onclick={() => switchTo(role as DemoRole)}
            class="rounded-full px-2.5 py-0.5 text-label-md font-label-md transition-colors
              {role === activeRole
              ? 'bg-primary text-on-primary'
              : 'bg-inverse-on-surface/10 hover:bg-inverse-on-surface/20'}"
            aria-pressed={role === activeRole}
          >
            {account.label}
          </button>
        {/each}
        {#if switching}
          <span class="text-label-md opacity-70">wechsle…</span>
        {/if}
      </span>
    {/if}
  </div>
{/if}

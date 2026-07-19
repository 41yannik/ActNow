<script lang="ts">
  // Fixed portfolio-demo bar: labels the app as non-persistent and switches
  // between the two completely local display roles.
  import { goto } from '$app/navigation';
  import { DEMO_ROLES, demoSession, type DemoRole } from '$lib/demo/session.svelte';

  async function switchTo(role: DemoRole) {
    if (role === demoSession.activeRole) return;
    await goto(demoSession.switchRole(role));
  }
</script>

<div
  class="sticky top-0 z-50 flex flex-wrap items-center justify-center gap-x-3 gap-y-1 border-b border-outline bg-inverse-surface px-3 py-1.5 text-inverse-on-surface"
>
  <span class="text-label-md font-label-md">
    Interaktive Demo · Änderungen werden nicht gespeichert
  </span>
  <span class="flex items-center gap-1" role="group" aria-label="Demo-Ansicht wechseln">
    {#each Object.entries(DEMO_ROLES) as [role, account] (role)}
      <button
        type="button"
        onclick={() => switchTo(role as DemoRole)}
        class="rounded-full px-2.5 py-0.5 text-label-md font-label-md transition-colors
          {role === demoSession.activeRole
          ? 'bg-primary text-on-primary'
          : 'bg-inverse-on-surface/10 hover:bg-inverse-on-surface/20'}"
        aria-pressed={role === demoSession.activeRole}
      >
        {account.label}
      </button>
    {/each}
  </span>
</div>

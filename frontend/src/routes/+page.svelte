<script lang="ts">
  import { onMount } from 'svelte';
  import { goto } from '$app/navigation';
  import { Button, PageHeader } from '$lib';
  import { auth } from '$lib/stores/auth.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';

  onMount(() => {
    // Redirect authenticated users to their home; leave anonymous on the landing.
    const stop = $effect.root(() => {
      $effect(() => {
        if (auth.loading) return;
        if (auth.isAuthenticated) {
          const target =
            auth.role === 'organization' || auth.role === 'admin' ? '/dashboard' : '/discover';
          void goto(target, { replaceState: true });
        }
      });
    });
    return stop;
  });
</script>

{#if auth.loading || auth.isAuthenticated}
  <div class="flex min-h-screen items-center justify-center"><LoadingSpinner /></div>
{:else}
  <main class="min-h-screen flex items-center justify-center p-md">
    <div class="max-w-xl text-center space-y-md">
      <PageHeader
        title="ActNow"
        subtitle="Verbinde dich mit Vereinen und Initiativen in deiner Nähe – oder finde Helfer:innen für dein Projekt."
      />
      <div class="flex flex-wrap justify-center gap-sm">
        <Button leadingIcon="login" onclick={() => goto('/login')}>Anmelden</Button>
        <Button variant="outlined" leadingIcon="person_add" onclick={() => goto('/register')}>
          Konto erstellen
        </Button>
      </div>
      <div class="pt-md">
        <a class="text-primary hover:underline" href="/showcase">Component Showcase</a>
      </div>
    </div>
  </main>
{/if}

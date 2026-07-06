<script lang="ts">
  import { goto } from '$app/navigation';
  import AuthLayout from '$lib/features/auth/components/AuthLayout.svelte';
  import RoleSelector from '$lib/features/auth/components/RoleSelector.svelte';
  import TextField from '$lib/components/forms/TextField.svelte';
  import PasswordInput from '$lib/components/forms/PasswordInput.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Alert from '$lib/components/ui/Alert.svelte';
  import { signUp } from '$lib/services/supabase/auth';
  import { registerSchema } from '$lib/validation/auth';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { DEMO_MODE } from '$lib/config/demo';
  import { onMount } from 'svelte';
  import type { UserRole } from '$lib/types/database';

  onMount(() => {
    if (DEMO_MODE) void goto('/discover');
  });

  let role = $state<UserRole>('helper');
  let display_name = $state('');
  let org_name = $state('');
  let email = $state('');
  let password = $state('');
  let terms = $state(false);
  let submitting = $state(false);
  let error = $state<string | null>(null);

  async function submit(e: Event) {
    e.preventDefault();
    error = null;

    if (!terms) {
      error = 'Bitte akzeptiere die Nutzungsbedingungen und die Datenschutzerklärung.';
      return;
    }
    const data = {
      role,
      email,
      password,
      display_name: role === 'organization' ? org_name : display_name,
      organization_name: role === 'organization' ? org_name : undefined,
      accept_terms: terms,
    };
    const parsed = registerSchema.safeParse(data);
    if (!parsed.success) {
      error = parsed.error.issues[0]?.message ?? 'Ungültige Eingabe';
      return;
    }
    submitting = true;
    try {
      await signUp({
        email: parsed.data.email,
        password: parsed.data.password,
        role: parsed.data.role,
        display_name: parsed.data.display_name,
        organization_name: parsed.data.organization_name,
      });
      toasts.success('Konto erstellt!', 'Willkommen bei ActNow');
      await goto(role === 'organization' ? '/dashboard' : '/discover');
    } catch (err) {
      error = err instanceof Error ? err.message : 'Registrierung fehlgeschlagen';
    } finally {
      submitting = false;
    }
  }
</script>

<svelte:head><title>Registrieren · ActNow</title></svelte:head>

<AuthLayout title="Konto erstellen" subtitle="Wähle deinen Konto-Typ und leg los.">
  <form class="flex flex-col gap-md" onsubmit={submit}>
    {#if error}
      <Alert tone="error">{error}</Alert>
    {/if}
    <RoleSelector value={role} onchange={(r) => (role = r)} />

    {#if role === 'helper'}
      <TextField label="Name" autocomplete="name" required bind:value={display_name} />
    {:else}
      <TextField
        label="Name der Organisation"
        autocomplete="organization"
        required
        bind:value={org_name}
      />
    {/if}
    <TextField type="email" label="E-Mail" autocomplete="email" required bind:value={email} />
    <PasswordInput
      label="Passwort"
      autocomplete="new-password"
      required
      helper="Mindestens 8 Zeichen."
      bind:value={password}
    />
    <div class="flex items-start gap-2">
      <input
        id="terms-checkbox"
        type="checkbox"
        bind:checked={terms}
        class="mt-1 h-4 w-4 rounded border-outline text-primary focus:ring-primary flex-shrink-0 cursor-pointer accent-primary"
      />
      <label
        for="terms-checkbox"
        class="text-body-md font-body-md text-on-surface cursor-pointer flex-1"
      >
        <span class="block">
          Ich akzeptiere die
          <a
            href="/agb"
            class="text-primary hover:underline cursor-pointer font-semibold"
            target="_blank"
            rel="noopener noreferrer"
          >
            AGB
          </a>
          und die
          <a
            href="/datenschutz"
            class="text-primary hover:underline cursor-pointer font-semibold"
            target="_blank"
            rel="noopener noreferrer"
          >
            Datenschutzerklärung
          </a>
          .
        </span>
      </label>
    </div>
    <Button type="submit" disabled={submitting}>
      {submitting ? 'Registriere…' : 'Konto erstellen'}
    </Button>
  </form>
  {#snippet footer()}
    Bereits ein Konto?
    <a class="text-primary hover:underline" href="/login">Anmelden</a>
  {/snippet}
</AuthLayout>

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
  import type { UserRole } from '$lib/types/database';

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
      error = 'Bitte akzeptiere die AGB.';
      return;
    }
    const data = {
      role,
      email,
      password,
      display_name,
      org_name: role === 'organization' ? org_name : undefined
    };
    const parsed = registerSchema.safeParse(data);
    if (!parsed.success) {
      error = parsed.error.issues[0]?.message ?? 'Ungültige Eingabe';
      return;
    }
    submitting = true;
    try {
      const finalDisplay = role === 'organization' ? org_name : display_name;
      await signUp({
        email: parsed.data.email,
        password: parsed.data.password,
        role: parsed.data.role,
        display_name: finalDisplay,
        organization_name: role === 'organization' ? org_name : undefined
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
      <TextField label="Name der Organisation" autocomplete="organization" required bind:value={org_name} />
    {/if}
    <TextField type="email" label="E-Mail" autocomplete="email" required bind:value={email} />
    <PasswordInput
      label="Passwort"
      autocomplete="new-password"
      required
      helper="Mindestens 8 Zeichen."
      bind:value={password}
    />
    <label class="flex items-start gap-2 text-body-md font-body-md text-on-surface">
      <input
        type="checkbox"
        bind:checked={terms}
        class="mt-1 h-4 w-4 rounded border-outline text-primary focus:ring-primary"
      />
      <span>
        Ich akzeptiere die <a class="text-primary hover:underline" href="/agb">AGB</a> und die
        <a class="text-primary hover:underline" href="/datenschutz">Datenschutzerklärung</a>.
      </span>
    </label>
    <Button type="submit" disabled={submitting}>
      {submitting ? 'Registriere…' : 'Konto erstellen'}
    </Button>
  </form>
  {#snippet footer()}
    Bereits ein Konto?
    <a class="text-primary hover:underline" href="/login">Anmelden</a>
  {/snippet}
</AuthLayout>

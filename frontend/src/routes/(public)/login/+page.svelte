<script lang="ts">
  import { goto } from '$app/navigation';
  import { page } from '$app/state';
  import AuthLayout from '$lib/features/auth/components/AuthLayout.svelte';
  import TextField from '$lib/components/forms/TextField.svelte';
  import PasswordInput from '$lib/components/forms/PasswordInput.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Alert from '$lib/components/ui/Alert.svelte';
  import { signIn } from '$lib/services/supabase/auth';
  import { auth } from '$lib/stores/auth.svelte';
  import { loginSchema } from '$lib/validation/auth';
  import { toasts } from '$lib/stores/toasts.svelte';

  let email = $state('');
  let password = $state('');
  let submitting = $state(false);
  let error = $state<string | null>(null);

  async function submit(e: Event) {
    e.preventDefault();
    error = null;
    const parsed = loginSchema.safeParse({ email, password });
    if (!parsed.success) {
      error = parsed.error.issues[0]?.message ?? 'Ungültige Eingabe';
      return;
    }
    submitting = true;
    try {
      await signIn(parsed.data.email, parsed.data.password);
      toasts.success('Willkommen zurück!');
      const next = page.url.searchParams.get('next');
      // Wait briefly for auth store to load profile/role.
      await new Promise((r) => setTimeout(r, 100));
      const role = auth.role;
      const target =
        next ?? (role === 'organization' || role === 'admin' ? '/dashboard' : '/discover');
      await goto(target);
    } catch (err) {
      error = err instanceof Error ? err.message : 'Anmeldung fehlgeschlagen';
    } finally {
      submitting = false;
    }
  }
</script>

<svelte:head><title>Anmelden · ActNow</title></svelte:head>

<AuthLayout title="Willkommen zurück" subtitle="Melde dich mit deinem Konto an.">
  <form class="flex flex-col gap-md" onsubmit={submit}>
    {#if error}
      <Alert tone="error">{error}</Alert>
    {/if}
    <TextField type="email" label="E-Mail" autocomplete="email" required bind:value={email} />
    <PasswordInput label="Passwort" autocomplete="current-password" required bind:value={password} />
    <Button type="submit" disabled={submitting}>{submitting ? 'Anmelden…' : 'Anmelden'}</Button>
  </form>
  {#snippet footer()}
    Noch kein Konto?
    <a class="text-primary hover:underline" href="/register">Jetzt registrieren</a>
  {/snippet}
</AuthLayout>

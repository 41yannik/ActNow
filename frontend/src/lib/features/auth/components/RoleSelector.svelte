<script lang="ts">
  // Role chooser used during sign-up.
  import RadioCard from '$lib/components/forms/RadioCard.svelte';
  import type { UserRole } from '$lib/types/database';

  interface Props {
    value: UserRole;
    onchange: (next: UserRole) => void;
    class?: string;
  }
  const { value, onchange, class: klass = '' }: Props = $props();

  let group = $state<string>(value);
  $effect(() => {
    group = value;
  });
  $effect(() => {
    if ((group === 'helper' || group === 'organization') && group !== value) {
      onchange(group);
    }
  });
</script>

<fieldset class="grid grid-cols-1 gap-sm sm:grid-cols-2 {klass}">
  <legend class="sr-only">Konto-Typ</legend>
  <RadioCard
    name="role"
    value="helper"
    bind:group
    icon="volunteer_activism"
    label="Ich möchte helfen"
    description="Engagiere dich für gemeinnützige Aktionen in deiner Nähe."
  />
  <RadioCard
    name="role"
    value="organization"
    bind:group
    icon="apartment"
    label="Wir suchen Helfer:innen"
    description="Erstelle Angebote als Verein, Initiative oder Organisation."
  />
</fieldset>

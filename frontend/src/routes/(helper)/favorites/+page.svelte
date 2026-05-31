<script lang="ts">
  // Platzhalter — wird in Phase 2 ausgebaut (gespeicherte Tätigkeiten + Organisationen).
  import SageHeader from '$lib/components/layout/SageHeader.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
</script>

<svelte:head><title>Favoriten · ActNow</title></svelte:head>

<section class="mx-auto w-full max-w-2xl">
  <SageHeader title="Favoriten" subtitle="Deine gespeicherten Aktionen" unread={2} />
  <div class="p-md">
    <EmptyState
      icon="favorite"
      title="Bald verfügbar"
      description="Hier erscheinen die Tätigkeiten und Organisationen, die du speicherst."
    />
  </div>
</section>

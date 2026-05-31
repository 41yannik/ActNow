<script lang="ts">
  // Platzhalter — wird in Phase 3 ausgebaut (Punkte, Stufen, Reward-Grid).
  import SageHeader from '$lib/components/layout/SageHeader.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
</script>

<svelte:head><title>Rewards · ActNow</title></svelte:head>

<section class="mx-auto w-full max-w-2xl">
  <SageHeader title="Rewards" subtitle="Sammle Punkte und sichere dir Rabatte" unread={2} />
  <div class="p-md">
    <EmptyState
      icon="star"
      title="Bald verfügbar"
      description="Punkte, Stufen und einlösbare Rewards folgen in Kürze."
    />
  </div>
</section>

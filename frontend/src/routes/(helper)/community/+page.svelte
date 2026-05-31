<script lang="ts">
  // Platzhalter — wird in Phase 2 ausgebaut (Chats + Aktivitäten-Feed).
  import SageHeader from '$lib/components/layout/SageHeader.svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';
</script>

<svelte:head><title>Community · ActNow</title></svelte:head>

<section class="mx-auto w-full max-w-2xl">
  <SageHeader title="Community" subtitle="Chats und Aktivitäten an einem Ort" unread={2} />
  <div class="p-md">
    <EmptyState
      icon="forum"
      title="Bald verfügbar"
      description="Chats und der Aktivitäten-Feed werden in Kürze hier erscheinen."
    />
  </div>
</section>

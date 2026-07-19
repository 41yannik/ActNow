<script lang="ts">
  import { goto } from '$app/navigation';
</script>

<svelte:head><title>Demo-Hinweise · ActNow</title></svelte:head>

<div class="min-h-screen bg-surface">
  <div class="border-b border-outline p-lg">
    <button onclick={() => goto('/')} class="font-body-md text-primary hover:underline">
      ← Zurück zur Startseite
    </button>
  </div>

  <main class="mx-auto w-full max-w-2xl space-y-lg p-lg text-body-md font-body-md text-on-surface">
    <h1 class="text-display-lg font-display-lg">Hinweise zur Portfolio-Demo</h1>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">Kein produktiver Dienst</h2>
      <p>
        ActNow demonstriert ausschließlich Gestaltung und Funktionskonzept eines Masterprojekts.
        Über diese Website werden keine Engagements vermittelt und keine rechtsverbindlichen
        Erklärungen abgegeben.
      </p>
    </section>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">Fiktive Inhalte</h2>
      <p>
        Sämtliche Personen, Organisationen, Profile, Nachrichten, Bewertungen und Angebote sind
        Beispieldaten. Ähnlichkeiten mit realen Personen oder Organisationen sind unbeabsichtigt.
      </p>
    </section>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">Interaktionen</h2>
      <p>
        Navigation, Filter, Swipe-Deck und Formulare können ausprobiert werden. Schreibende Aktionen
        werden nicht ausgeführt, nicht übertragen und nicht gespeichert. Ein Neuladen der Seite
        stellt den Ausgangszustand wieder her.
      </p>
    </section>
  </main>
</div>

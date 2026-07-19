<script lang="ts">
  import { goto } from '$app/navigation';
</script>

<svelte:head><title>Impressum · ActNow Portfolio-Demo</title></svelte:head>

<div class="min-h-screen bg-surface">
  <div class="border-b border-outline p-lg">
    <button onclick={() => goto('/')} class="font-body-md text-primary hover:underline">
      ← Zurück zur Startseite
    </button>
  </div>

  <main class="mx-auto w-full max-w-2xl space-y-lg p-lg text-body-md font-body-md text-on-surface">
    <h1 class="text-display-lg font-display-lg">Impressum</h1>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">Anbieter</h2>
      <p>
        ActNow ist ein Projekt im Portfolio von Yannik Huber. Die vollständigen und aktuellen
        Anbieter- und Kontaktangaben stehen im zentralen
        <a
          href="https://yannik-h-huber.de/impressum/"
          class="text-primary hover:underline"
          rel="external"
        >
          Impressum des Portfolios
        </a>.
      </p>
    </section>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">Projektinformation</h2>
      <p>
        ActNow ist eine nicht kommerzielle Portfolio-Demo eines Masterprojekts. Die dargestellte
        Plattform ist nicht produktiv nutzbar; Personen, Organisationen, Angebote und Nachrichten
        sind fiktiv.
      </p>
    </section>

    <p class="border-t border-outline pt-lg text-on-surface-variant">
      Technischer Stand: Juli 2026. Für die Anbieterangaben gilt das verlinkte zentrale Impressum.
    </p>
  </main>
</div>

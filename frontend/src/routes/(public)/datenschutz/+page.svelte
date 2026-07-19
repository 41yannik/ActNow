<script lang="ts">
  import { goto } from '$app/navigation';
</script>

<svelte:head><title>Datenschutz · ActNow Portfolio-Demo</title></svelte:head>

<div class="min-h-screen bg-surface">
  <div class="border-b border-outline p-lg">
    <button onclick={() => goto('/')} class="font-body-md text-primary hover:underline">
      ← Zurück zur Startseite
    </button>
  </div>

  <main class="mx-auto w-full max-w-2xl space-y-lg p-lg text-body-md font-body-md text-on-surface">
    <h1 class="text-display-lg font-display-lg">Datenschutzerklärung</h1>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">1. Verantwortlicher</h2>
      <p>
        Verantwortlich ist der Betreiber des Portfolios yannik-h-huber.de. Die vollständigen
        Kontakt- und Anbieterangaben stehen im
        <a
          href="https://yannik-h-huber.de/impressum/"
          class="text-primary hover:underline"
          rel="external"
        >
          zentralen Portfolio-Impressum
        </a>.
      </p>
    </section>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">2. Art der Website</h2>
      <p>
        ActNow ist eine statische, interaktive Portfolio-Demo eines Masterprojekts. Es gibt keine
        Registrierung, Benutzerkonten, Datenbank oder Übertragung von Formular-, Profil- oder
        Nachrichteneingaben. Alle dargestellten Inhalte sind fiktive Beispieldaten.
      </p>
    </section>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">3. Lokale Speicherung und externe Inhalte</h2>
      <p>
        Die Demo speichert keinen Anwendungszustand in Cookies, Local Storage, Session Storage oder
        IndexedDB. Schriften, Symbole und Bilder werden zusammen mit der Website ausgeliefert; es
        werden dafür keine externen Font- oder Mediendienste aufgerufen.
      </p>
    </section>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">4. Hosting</h2>
      <p>
        Die statischen Dateien werden über GitHub Pages bereitgestellt. Beim Abruf können durch den
        Hostinganbieter technisch erforderliche Zugriffsdaten wie IP-Adresse, Zeitpunkt, aufgerufene
        Datei und Browserinformationen verarbeitet werden. Einzelheiten ergeben sich aus den
        Datenschutzinformationen von GitHub.
      </p>
    </section>

    <section class="space-y-sm">
      <h2 class="text-title-lg font-title-lg">5. Kontakt und Betroffenenrechte</h2>
      <p>
        Fragen zum Datenschutz und gesetzliche Betroffenenanfragen können an die im Portfolio
        genannte Kontaktadresse gerichtet werden. Ergänzend gilt die
        <a
          href="https://yannik-h-huber.de/datenschutz/"
          class="text-primary hover:underline"
          rel="external"
        >
          zentrale Datenschutzerklärung
        </a>.
      </p>
    </section>

    <p class="border-t border-outline pt-lg text-on-surface-variant">
      Technischer Stand: Juli 2026. Diese Vorlage ersetzt keine individuelle rechtliche Prüfung.
    </p>
  </main>
</div>

<script lang="ts">
  import { goto } from '$app/navigation';
</script>

<!-- TODO(legal): Platzhalter in eckigen Klammern vor Produktiv-Launch durch echte Angaben ersetzen -->

<svelte:head><title>Impressum · ActNow</title></svelte:head>

<div class="min-h-screen bg-surface flex flex-col">
  <!-- Navigation -->
  <div class="p-lg border-b border-outline">
    <button
      onclick={() => goto('/')}
      class="text-primary hover:underline font-body-md"
    >
      ← Zurück zur Startseite
    </button>
  </div>

  <!-- Content -->
  <div class="flex-1 p-lg max-w-2xl mx-auto w-full">
    <h1 class="text-display-lg font-display-lg mb-lg">Impressum</h1>

    <div class="space-y-lg text-body-md font-body-md text-on-surface">
      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">Angaben gemäß § 5 DDG</h2>
        <p>
          [Name des Anbieters / der Organisation]<br />
          [Rechtsform, z. B. e. V., GbR, UG (haftungsbeschränkt)]
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">Anschrift</h2>
        <p>
          [Straße Hausnummer]<br />
          [PLZ Ort]<br />
          Deutschland
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">Vertreten durch</h2>
        <p>[Vor- und Nachname der vertretungsberechtigten Person(en)]</p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">Kontakt</h2>
        <p>
          E-Mail: [E-Mail-Adresse]<br />
          Telefon: [Telefonnummer, optional]
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">Registereintrag und Umsatzsteuer</h2>
        <p>
          [Sofern zutreffend: Registergericht, Registernummer (z. B. Vereinsregister) sowie
          Umsatzsteuer-Identifikationsnummer gemäß § 27a UStG. Andernfalls diesen Abschnitt entfernen.]
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">Verantwortlich i. S. d. § 18 Abs. 2 MStV</h2>
        <p>
          [Vor- und Nachname]<br />
          [Straße Hausnummer]<br />
          [PLZ Ort]
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">EU-Streitschlichtung und Verbraucherstreitbeilegung</h2>
        <p>
          Wir sind nicht bereit oder verpflichtet, an Streitbeilegungsverfahren vor einer
          Verbraucherschlichtungsstelle teilzunehmen.
        </p>
      </section>

      <p class="text-on-surface-variant pt-lg border-t border-outline">
        Letzte Aktualisierung: Juni 2026
      </p>
    </div>
  </div>
</div>

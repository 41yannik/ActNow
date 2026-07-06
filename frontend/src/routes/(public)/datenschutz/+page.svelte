<script lang="ts">
  import { goto } from '$app/navigation';
</script>

<svelte:head><title>Datenschutzerklärung · ActNow</title></svelte:head>

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
    <h1 class="text-display-lg font-display-lg mb-lg">Datenschutzerklärung</h1>
    
    <div class="space-y-lg text-body-md font-body-md text-on-surface">
      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">1. Verantwortlicher</h2>
        <p>
          Die Verantwortliche Person für die Verarbeitung Ihrer personenbezogenen Daten ist ActNow.
          Kontaktieren Sie uns unter den Kontaktinformationen in unserem
          <a href="/impressum" class="text-primary hover:underline">Impressum</a>.
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">2. Datenverarbeitung</h2>
        <p>
          ActNow erhebt und verarbeitet Daten, um die Plattform zu betreiben und Ihnen unsere Dienste bereitzustellen.
          Dies umfasst:
        </p>
        <ul class="list-disc list-inside space-y-sm">
          <li>Registrierungsdaten (Name, E-Mail, Passwort)</li>
          <li>Profildaten und Präferenzen</li>
          <li>Aktivitätsdaten auf der Plattform</li>
          <li>Kommunikationsdaten</li>
        </ul>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">3. Ihre Rechte</h2>
        <p>Sie haben das Recht:</p>
        <ul class="list-disc list-inside space-y-sm">
          <li>Auskunft über Ihre personenbezogenen Daten zu erhalten</li>
          <li>Unrichtige Daten korrigieren zu lassen</li>
          <li>Die Löschung Ihrer Daten zu verlangen</li>
          <li>Der Verarbeitung Ihrer Daten zu widersprechen</li>
        </ul>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">4. Datensicherheit</h2>
        <p>
          Wir schützen Ihre Daten durch angemessene technische und organisatorische Sicherheitsmaßnahmen.
          Trotz unserer Bemühungen können wir keine absolute Sicherheit garantieren.
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">5. Speicherdauer</h2>
        <p>
          Ihre personenbezogenen Daten werden so lange gespeichert, wie nötig, um die Dienste bereitzustellen
          oder wie gesetzlich erforderlich. Bei Kontolöschung werden Ihre Daten gelöscht, sofern keine
          gesetzlichen Aufbewahrungspflichten bestehen.
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">6. Kontakt</h2>
        <p>
          Für Fragen zum Datenschutz kontaktieren Sie uns über das Kontaktformular oder schreiben Sie uns
          an die im <a href="/impressum" class="text-primary hover:underline">Impressum</a> angegebene
          E-Mail-Adresse.
        </p>
      </section>

      <p class="text-on-surface-variant pt-lg border-t border-outline">
        Letzte Aktualisierung: Juni 2026
      </p>
    </div>
  </div>
</div>

<script lang="ts">
  import { goto } from '$app/navigation';
</script>

<svelte:head><title>Allgemeine Geschäftsbedingungen · ActNow</title></svelte:head>

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
    <h1 class="text-display-lg font-display-lg mb-lg">Allgemeine Geschäftsbedingungen (AGB)</h1>
    
    <div class="space-y-lg text-body-md font-body-md text-on-surface">
      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">1. Geltungsbereich</h2>
        <p>
          Diese AGB regeln die Nutzung der ActNow-Plattform durch Nutzer. Mit der Registrierung akzeptieren
          Sie diese Bedingungen in vollem Umfang.
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">2. Nutzungsrechte</h2>
        <p>
          ActNow räumt Ihnen ein nicht ausschließliches, widerrufliches Recht zur Nutzung der Plattform
          ein, um gemeinnützige Aktivitäten zu unterstützen oder zu organisieren.
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">3. Nutzungsbeschränkungen</h2>
        <p>Sie versprechen, die Plattform nicht zu nutzen, um:</p>
        <ul class="list-disc list-inside space-y-sm">
          <li>Inhalte hochzuladen, die rechtswidrig, diffamierend oder belästigend sind</li>
          <li>Andere Nutzer zu belästigen oder zu bedrohen</li>
          <li>Werbung oder Spam zu verbreiten</li>
          <li>Die Plattform zu hacken oder zu manipulieren</li>
          <li>Geschützte Inhalte Dritter zu verletzen</li>
        </ul>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">4. Verantwortung der Nutzer</h2>
        <p>
          Sie sind verantwortlich für alle Aktivitäten auf Ihrem Konto. Sie versprechen, Ihre
          Anmeldedaten vertraulich zu behandeln und niemanden anderen Zugriff zu geben.
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">5. Inhalte und Rechte</h2>
        <p>
          Nutzergenerierte Inhalte bleiben Eigentum des Nutzers. Mit dem Hochladen von Inhalten
          räumen Sie ActNow ein Recht ein, diese zu hosten und anzuzeigen.
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">6. Haftungsausschluss</h2>
        <p>
          Die Plattform wird "wie besehen" zur Verfügung gestellt. ActNow wird nicht haftbar gemacht
          für Datenverlust, Unterbrechungen oder Schäden, die sich aus der Nutzung ergeben.
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">7. Kündigung</h2>
        <p>
          ActNow behält sich das Recht vor, Konten zu sperren oder zu löschen, die gegen diese AGB verstoßen
          oder missbräuchlich verwendet werden.
        </p>
      </section>

      <section class="space-y-md">
        <h2 class="text-title-lg font-title-lg">8. Änderungen der AGB</h2>
        <p>
          Wir können diese AGB jederzeit ändern. Eine fortgesetzte Nutzung der Plattform nach Änderungen
          bedeutet Zustimmung zu den neuen Bedingungen.
        </p>
      </section>

      <p class="text-on-surface-variant pt-lg border-t border-outline">
        Letzte Aktualisierung: Juni 2026
      </p>
    </div>
  </div>
</div>

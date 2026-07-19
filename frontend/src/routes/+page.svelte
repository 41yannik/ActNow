<script lang="ts">
  import { goto } from '$app/navigation';
  import Button from '$lib/components/ui/Button.svelte';
  import Icon from '$lib/components/ui/Icon.svelte';
  import { demoSession, type DemoRole } from '$lib/demo/session.svelte';

  async function startDemo(role: DemoRole) {
    await goto(demoSession.switchRole(role));
  }
</script>

<svelte:head><title>ActNow · Interaktive Portfolio-Demo</title></svelte:head>

<main class="min-h-[calc(100vh-2.5rem)] bg-background px-md py-xl md:px-xl">
  <section class="mx-auto flex max-w-5xl flex-col items-center gap-xl text-center">
    <div
      class="inline-flex items-center gap-2 rounded-full bg-secondary-container px-4 py-2 text-label-lg font-label-lg text-on-secondary-container"
    >
      <Icon name="visibility" size={19} />
      Interaktive Masterprojekt-Demo · keine echte Plattform
    </div>

    <div class="max-w-3xl space-y-md">
      <img src="/logo_actnow.png" alt="ActNow" class="mx-auto h-24 w-24 object-contain" />
      <h1 class="text-display-lg font-display-lg text-on-background md:text-[64px]">ActNow</h1>
      <p class="text-title-lg font-title-lg text-on-surface-variant">
        Entdecke, wie Helfer:innen und gemeinnützige Organisationen passende Einsätze finden und
        gemeinsam Wirkung schaffen könnten.
      </p>
    </div>

    <div class="grid w-full max-w-3xl gap-md md:grid-cols-2">
      <article class="rounded-3xl bg-surface-container-lowest p-lg text-left shadow-sm">
        <Icon name="volunteer_activism" size={38} class="text-primary" />
        <h2 class="mt-md text-headline-sm font-headline-sm">Helfer-Ansicht</h2>
        <p class="my-sm text-body-lg font-body-lg text-on-surface-variant">
          Angebote swipen, Einsätze, Kalender, Favoriten, Community und Profil erkunden.
        </p>
        <Button
          class="mt-md w-full"
          leadingIcon="arrow_forward"
          onclick={() => startDemo('helper')}
        >
          Als Helferin erkunden
        </Button>
      </article>

      <article class="rounded-3xl bg-surface-container-lowest p-lg text-left shadow-sm">
        <Icon name="domain" size={38} class="text-primary" />
        <h2 class="mt-md text-headline-sm font-headline-sm">Vereins-Ansicht</h2>
        <p class="my-sm text-body-lg font-body-lg text-on-surface-variant">
          Dashboard, Angebote, Bewerbungen, Nachrichten und Organisationsprofil ansehen.
        </p>
        <Button
          class="mt-md w-full"
          variant="outlined"
          leadingIcon="arrow_forward"
          onclick={() => startDemo('org')}
        >
          Als Verein erkunden
        </Button>
      </article>
    </div>

    <div class="max-w-3xl rounded-2xl border border-outline-variant bg-surface-container p-md">
      <p class="text-body-md font-body-md text-on-surface-variant">
        Alle dargestellten Personen, Organisationen, Nachrichten und Einsätze sind fiktive
        Beispieldaten. Es gibt keine Anmeldung, keine Datenübertragung und keine dauerhaften
        Änderungen. Ein Neuladen stellt den Ausgangszustand wieder her.
      </p>
    </div>

    <nav
      class="flex flex-wrap justify-center gap-md text-label-lg font-label-lg"
      aria-label="Weitere Seiten"
    >
      <a class="text-primary hover:underline" href="/showcase">Component Showcase</a>
      <a class="text-primary hover:underline" href="/datenschutz">Datenschutz</a>
      <a class="text-primary hover:underline" href="/impressum">Impressum</a>
    </nav>
  </section>
</main>

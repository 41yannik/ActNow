<script lang="ts">
  import {
    Button, IconButton, Chip, Avatar, OrgLogo, RatingStars, Badge, Tag,
    EmptyState, LoadingSpinner, Alert,
    TextField, TextArea, Select, Checkbox, Radio, CheckboxCard, RadioCard, FormSection,
    TopNavBar, BottomNavBar, PageHeader,
    SwipeDeck, SwipeActionBar
  } from '$lib';
  import type { Offer } from '$lib/types/domain';
  import type { SwipeEvent } from '$lib/features/offers/components/swipe.types';

  // ── Demo data ────────────────────────────────────────────────────────────
  const demoOffers: Offer[] = [
    {
      id: 'o-1',
      title: 'Hausaufgabenhilfe für Kids',
      description:
        'Wir suchen engagierte Helfer, die Grundschulkindern bei den Hausaufgaben in Mathe und Deutsch unter die Arme greifen. Keine Vorkenntnisse nötig, nur Geduld und Freude an der Arbeit mit Kindern.',
      offer_type: 'recurring_event',
      status: 'published',
      organization_id: 'org-1',
      organization_name: 'Lernzentrum Berlin e.V.',
      organization_avatar_url: null,
      organization_rating: 4.9,
      cover_image_url: null,
      city: 'Berlin Kreuzberg',
      is_remote: false,
      schedule_text: 'Jeden Dienstag, 15:00 – 17:00',
      helpers_needed: 4,
      accepted_helpers_count: 2,
      starts_at: null
    },
    {
      id: 'o-2',
      title: 'Parkreinigung Stadtmitte',
      description:
        'Gemeinsam mit Nachbar:innen sammeln wir Müll im Stadtpark und sorgen für ein schöneres Viertel. Handschuhe & Säcke werden gestellt.',
      offer_type: 'single_event',
      status: 'published',
      organization_id: 'org-2',
      organization_name: 'UmweltHilfe e.V.',
      organization_avatar_url: null,
      organization_rating: 4.6,
      cover_image_url: null,
      city: 'Berlin Mitte',
      is_remote: false,
      schedule_text: 'Samstag, 09:00 – 12:00',
      helpers_needed: 10,
      accepted_helpers_count: 4,
      starts_at: null
    },
    {
      id: 'o-3',
      title: 'Übersetzung Webseite EN → DE',
      description:
        'Wir brauchen Hilfe bei der Übersetzung unserer Vereinswebseite. Etwa 2.000 Wörter, vollständig digital, Zeit flexibel einteilbar.',
      offer_type: 'digital_task',
      status: 'published',
      organization_id: 'org-3',
      organization_name: 'Initiative Bunte Stadt',
      organization_avatar_url: null,
      organization_rating: 5.0,
      cover_image_url: null,
      city: null,
      is_remote: true,
      schedule_text: 'Flexibel, bis Ende des Monats',
      helpers_needed: 1,
      accepted_helpers_count: 0,
      starts_at: null
    }
  ];

  // ── Swipe wiring ─────────────────────────────────────────────────────────
  let deck: ReturnType<typeof SwipeDeck> | null = $state(null);
  let log: string[] = $state([]);
  let queue = $state([...demoOffers]);

  function handleSwipe(e: SwipeEvent) {
    const verb = e.direction === 'right' ? 'Bewerben' : 'Verworfen';
    log = [`${verb} → ${e.offerId}`, ...log].slice(0, 6);
  }
  function handleEmpty() {
    log = ['Deck leer 🎉', ...log].slice(0, 6);
  }
  function reset() {
    queue = [...demoOffers];
    log = ['Reset', ...log].slice(0, 6);
  }

  // ── Form demo state ──────────────────────────────────────────────────────
  let textValue = $state('');
  let descValue = $state('');
  let categoryValue: string | '' = $state('');
  let role = $state('helper');
  let locationType = $state('on_site');
  let requireDriving = $state(false);
  let requireFitness = $state(true);
  let agree = $state(false);
</script>

<TopNavBar />

<main class="max-w-container-max mx-auto px-md md:px-xl py-lg space-y-xl pb-[120px] md:pb-xl">
  <PageHeader
    title="ActNow Component Showcase"
    subtitle="Foundations, primitives, forms, layout & the SwipeDeck — driven entirely by the shared library."
  />

  <!-- ── SwipeDeck (key feature) ───────────────────────────────────────── -->
  <section class="space-y-md">
    <h2 class="font-h2 text-h2-mobile md:text-h2 text-on-surface">★ SwipeDeck</h2>
    <p class="text-on-surface-variant max-w-2xl">
      Drag the top card or use the buttons / arrow keys. Cards beyond the top
      are rendered as visual depth only.
    </p>

    <div class="flex flex-col items-center gap-md">
      <SwipeDeck
        bind:this={deck}
        offers={queue}
        onswipe={handleSwipe}
        onempty={handleEmpty}
      />

      <SwipeActionBar
        canUndo={true}
        onundo={() => deck?.undoLast()}
        onreject={() => deck?.swipeLeft()}
        onsave={() => log = ['Favorit → ' + (deck?.topOfferId() ?? '—'), ...log].slice(0, 6)}
        onaccept={() => deck?.swipeRight()}
      />

      <div class="flex gap-sm">
        <Button variant="outlined" size="sm" leadingIcon="refresh" onclick={reset}>Reset Deck</Button>
      </div>

      {#if log.length}
        <ul class="text-[13px] text-on-surface-variant font-body-md space-y-0.5 mt-sm">
          {#each log as line}<li>• {line}</li>{/each}
        </ul>
      {/if}
    </div>
  </section>

  <!-- ── Primitives ────────────────────────────────────────────────────── -->
  <section class="space-y-md">
    <h2 class="font-h2 text-h2-mobile md:text-h2 text-on-surface">Primitives</h2>

    <div class="bg-surface-container-lowest rounded-xl p-md shadow-sm space-y-md">
      <div class="flex flex-wrap gap-sm items-center">
        <Button>Primary</Button>
        <Button variant="secondary">Secondary</Button>
        <Button variant="outlined">Outlined</Button>
        <Button variant="text">Text</Button>
        <Button variant="danger">Danger</Button>
        <Button leadingIcon="add">Mit Icon</Button>
        <Button loading>Loading</Button>
        <IconButton icon="favorite" label="Favoriten" />
        <IconButton icon="delete" label="Löschen" tone="danger" />
      </div>

      <div class="flex flex-wrap gap-sm items-center">
        <Chip icon="location_on" label="Berlin" />
        <Chip icon="calendar_month" label="Dieses Wochenende" variant="selected" />
        <Chip icon="category" label="Bildung" />
        <Chip icon="wifi" label="Digital OK" />
      </div>

      <div class="flex flex-wrap gap-md items-center">
        <Avatar name="Sarah Weidner" />
        <Avatar name="Anna Schmidt" size="lg" status="online" />
        <Avatar name="Max Mustermann" size="xl" />
        <OrgLogo name="Lernzentrum Berlin" />
        <OrgLogo name="UH" size="lg" />
        <RatingStars value={4.5} count={27} />
        <RatingStars value={5} count={1} />
      </div>

      <div class="flex flex-wrap gap-sm items-center">
        <Badge status="published" />
        <Badge status="draft" />
        <Badge status="filled" />
        <Badge status="cancelled" />
        <Badge status="accepted" />
        <Badge status="rejected" />
        <Tag label="Lesepate" />
        <Tag label="Mathematik" removable onremove={() => alert('removed')} />
      </div>
    </div>
  </section>

  <!-- ── Feedback ──────────────────────────────────────────────────────── -->
  <section class="space-y-md">
    <h2 class="font-h2 text-h2-mobile md:text-h2 text-on-surface">Feedback</h2>
    <div class="grid md:grid-cols-2 gap-md">
      <Alert tone="success" title="Bewerbung gesendet">
        Der Verein wurde benachrichtigt und meldet sich in Kürze.
      </Alert>
      <Alert tone="error" title="Fehler">
        Bitte überprüfe deine Internetverbindung.
      </Alert>
      <div class="bg-surface-container-lowest rounded-xl p-md shadow-sm flex items-center justify-center">
        <LoadingSpinner size={36} />
      </div>
      <div class="bg-surface-container-lowest rounded-xl shadow-sm">
        <EmptyState
          icon="inbox"
          title="Noch keine Bewerbungen"
          description="Wenn jemand sich auf dein Angebot bewirbt, erscheint die Bewerbung hier."
        />
      </div>
    </div>
  </section>

  <!-- ── Forms ─────────────────────────────────────────────────────────── -->
  <section class="space-y-md">
    <h2 class="font-h2 text-h2-mobile md:text-h2 text-on-surface">Forms</h2>

    <div class="bg-surface-container-lowest rounded-xl p-md md:p-lg shadow-sm space-y-lg">
      <FormSection title="Basisinformationen" description="Diese Felder werden auf der Karte angezeigt.">
        <TextField label="Titel des Angebots" placeholder="z.B. Lesepaten gesucht" bind:value={textValue} />
        <TextArea label="Beschreibung" placeholder="Beschreibe die Aufgaben…" bind:value={descValue} />
        <div class="grid md:grid-cols-2 gap-md">
          <Select
            label="Kategorie"
            placeholder="Bitte wählen…"
            bind:value={categoryValue}
            options={[
              { value: 'education', label: 'Bildung & Mentoring' },
              { value: 'environment', label: 'Umweltschutz' },
              { value: 'social', label: 'Soziales & Pflege' },
              { value: 'crafts', label: 'Handwerk & Logistik' }
            ]}
          />
          <TextField type="number" label="Benötigte Helfer" value={1} min={1} />
        </div>
      </FormSection>

      <FormSection title="Helfer-Rolle">
        <div class="grid md:grid-cols-2 gap-md">
          <RadioCard
            name="role"
            value="helper"
            bind:group={role}
            icon="volunteer_activism"
            label="Ich möchte helfen"
            description="Finde Einsätze in deiner Nähe per Swipe."
          />
          <RadioCard
            name="role"
            value="organization"
            bind:group={role}
            icon="domain"
            label="Wir sind eine Organisation"
            description="Veröffentliche Angebote und finde Helfer:innen."
          />
        </div>
      </FormSection>

      <FormSection title="Ort">
        <div class="flex flex-wrap gap-md">
          <Radio name="loc" value="on_site" bind:group={locationType} label="Vor Ort" />
          <Radio name="loc" value="remote" bind:group={locationType} label="Digital / Remote" />
        </div>
      </FormSection>

      <FormSection title="Anforderungen">
        <div class="grid md:grid-cols-2 gap-sm">
          <CheckboxCard label="Führerschein Kl. B" bind:checked={requireDriving} />
          <CheckboxCard label="Körperliche Fitness" bind:checked={requireFitness} />
        </div>
        <Checkbox bind:checked={agree} label="Ich habe die Datenschutzhinweise gelesen." />
      </FormSection>

      <div class="pt-md flex justify-end gap-sm border-t border-outline-variant">
        <Button variant="outlined">Als Entwurf speichern</Button>
        <Button leadingIcon="send">Veröffentlichen</Button>
      </div>
    </div>
  </section>

  <!-- ── Layout note ──────────────────────────────────────────────────── -->
  <section class="space-y-md">
    <h2 class="font-h2 text-h2-mobile md:text-h2 text-on-surface">Layout</h2>
    <p class="text-on-surface-variant">
      <code class="text-primary">TopNavBar</code> is mounted at the top of this page.
      <code class="text-primary">BottomNavBar</code> is mounted below (mobile only).
      <code class="text-primary">SideNavBar</code> and <code class="text-primary">AppShell</code>
      are intended for the organization dashboard layout — see <code class="text-primary">$lib</code> exports.
    </p>
  </section>
</main>

<BottomNavBar />

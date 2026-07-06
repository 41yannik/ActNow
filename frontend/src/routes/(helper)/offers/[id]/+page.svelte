<script lang="ts">
  import { onMount } from 'svelte';
  import { page } from '$app/state';
  import Icon from '$lib/components/ui/Icon.svelte';
  import CategoryBadge from '$lib/components/ui/CategoryBadge.svelte';
  import LoadingSpinner from '$lib/components/ui/LoadingSpinner.svelte';
  import { getOfferWithOrg } from '$lib/services/supabase/offers';
  import {
    createApplication,
    listApplicationsForHelper
  } from '$lib/services/supabase/applications';
  import { listSavedOfferIds, saveOffer, unsaveOffer } from '$lib/services/supabase/savedOffers';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { enrichOffer } from '$lib/features/offers/mockEnrich';

  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  let offer = $state<any | null>(null);
  let loading = $state(true);
  let saved = $state(false);
  let hasApplied = $state(false);
  let applying = $state(false);
  let showConfirm = $state(false);

  const offerId = $derived(page.params.id as string);
  const meta = $derived(offer ? enrichOffer(offer.id) : null);
  const org = $derived(offer?.organization?.profile ?? null);

  function fmtDate(iso: string | null) {
    return iso
      ? new Date(iso).toLocaleDateString('de-DE', { weekday: 'short', day: '2-digit', month: 'long' })
      : 'Flexibel';
  }
  function fmtTime(a: string | null, b: string | null) {
    if (!a) return 'Nach Absprache';
    const t = (s: string) =>
      new Date(s).toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
    return b ? `${t(a)} – ${t(b)}` : t(a);
  }

  const facts = $derived(
    offer
      ? [
          { icon: 'calendar_today', label: 'Datum', value: fmtDate(offer.starts_at) },
          { icon: 'schedule', label: 'Uhrzeit', value: fmtTime(offer.starts_at, offer.ends_at) },
          {
            icon: 'location_on',
            label: 'Ort',
            value: offer.is_remote
              ? 'Digital / Remote'
              : `${offer.city ?? offer.location_name ?? 'Vor Ort'}${meta ? `, ${meta.km} km` : ''}`
          },
          {
            icon: 'group',
            label: 'Plätze',
            value: offer.max_helpers
              ? `${Math.max(0, offer.max_helpers - (offer.accepted_helpers_count ?? 0))} von ${offer.max_helpers} frei`
              : 'Offen'
          }
        ]
      : []
  );

  const requirements = $derived(
    offer
      ? [
          { ok: true, t: 'Verifiziertes Profil' },
          { ok: true, t: `Mind. ${offer.min_age ?? 16} Jahre` },
          ...(offer.requires_documents ? [{ ok: false, t: 'Führungszeugnis' }] : []),
          ...((offer.skills_required ?? []) as string[]).map((s) => ({ ok: true, t: s }))
        ]
      : []
  );

  async function load() {
    loading = true;
    try {
      offer = await getOfferWithOrg(offerId);
      if (auth.profile) {
        const [savedSet, apps] = await Promise.all([
          listSavedOfferIds(auth.profile.id),
          listApplicationsForHelper(auth.profile.id)
        ]);
        saved = savedSet.has(offerId);
        hasApplied = (apps as Array<{ offer_id: string }>).some((a) => a.offer_id === offerId);
      }
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Konnte Angebot nicht laden');
    } finally {
      loading = false;
    }
  }

  onMount(load);

  async function toggleSave() {
    if (!auth.profile) return;
    const was = saved;
    saved = !was;
    try {
      if (was) await unsaveOffer(auth.profile.id, offerId);
      else {
        await saveOffer(auth.profile.id, offerId);
        toasts.success('In Favoriten gespeichert');
      }
    } catch (err) {
      saved = was;
      toasts.error(err instanceof Error ? err.message : 'Konnte nicht speichern');
    }
  }

  async function confirmApply() {
    if (!auth.profile || hasApplied) return;
    applying = true;
    try {
      await createApplication({
        offer_id: offerId,
        helper_profile_id: auth.profile.id,
        motivation_text: null
      });
      hasApplied = true;
      showConfirm = false;
      toasts.success('Bewerbung gesendet · +100 Punkte', offer?.title);
    } catch (err) {
      toasts.error(err instanceof Error ? err.message : 'Bewerbung fehlgeschlagen');
    } finally {
      applying = false;
    }
  }
</script>

<svelte:head><title>{offer?.title ?? 'Angebot'} · ActNow</title></svelte:head>

{#if loading}
  <div class="flex min-h-[60vh] items-center justify-center"><LoadingSpinner /></div>
{:else if !offer}
  <div class="p-md text-center text-on-surface-variant">Angebot nicht gefunden.</div>
{:else}
  <article class="mx-auto w-full max-w-2xl pb-32">
    <!-- Hero -->
    <div class="relative h-80 w-full bg-surface-container-low">
      <div class="flex h-full w-full items-center justify-center bg-gradient-to-br from-secondary-container to-primary">
        <Icon name="volunteer_activism" size={72} class="text-white/40" />
      </div>
      <div
        class="pointer-events-none absolute inset-0"
        style="background: linear-gradient(180deg, rgba(0,0,0,0.35) 0%, transparent 30%, transparent 65%, rgba(0,0,0,0.6) 100%);"
      ></div>

      <div class="absolute inset-x-4 top-4 flex justify-between" style="top: max(1rem, env(safe-area-inset-top));">
        <button
          type="button"
          onclick={() => history.back()}
          aria-label="Zurück"
          class="flex h-9 w-9 items-center justify-center rounded-full border-none bg-black/40 text-white backdrop-blur"
        >
          <Icon name="chevron_left" size={22} />
        </button>
        <button
          type="button"
          onclick={toggleSave}
          aria-label={saved ? 'Aus Favoriten entfernen' : 'Zu Favoriten hinzufügen'}
          class="flex h-9 w-9 items-center justify-center rounded-full border-none bg-black/40 text-white backdrop-blur"
        >
          <Icon name="bookmark" filled={saved} size={18} />
        </button>
      </div>

      <div class="absolute left-4 top-28 flex items-center gap-2">
        {#if offer.category}<CategoryBadge category={offer.category} />{/if}
        {#if meta?.sos}
          <span class="rounded-full bg-tertiary px-3 py-1 text-[11px] font-bold tracking-wider text-white">
            SOS · KURZFRISTIG
          </span>
        {/if}
      </div>

      <h1 class="absolute inset-x-4 bottom-4 text-[24px] font-bold leading-tight tracking-tight text-white">
        {offer.title}
      </h1>
    </div>

    <!-- Org row -->
    <div class="mx-4 mt-3.5 flex items-center gap-3 rounded-xl border border-outline-variant bg-surface p-3.5">
      <div class="flex h-11 w-11 shrink-0 items-center justify-center rounded-[10px] bg-primary-container text-[14px] font-bold text-white">
        {(org?.display_name ?? 'O')
          .split(' ')
          .map((w: string) => w[0])
          .slice(0, 2)
          .join('')}
      </div>
      <div class="min-w-0 flex-1">
        <div class="flex items-center gap-1.5">
          <span class="truncate text-[14px] font-bold text-on-secondary-container">{org?.display_name ?? 'Organisation'}</span>
          {#if offer.organization?.is_verified}
            <Icon name="verified" filled size={15} class="text-primary" />
          {/if}
        </div>
        <div class="mt-0.5 truncate text-[12px] text-on-surface-variant">
          {offer.organization?.is_verified ? 'Verifiziert' : 'Organisation'}
          {#if org?.average_rating}· {Number(org.average_rating).toFixed(1)} ★{/if}
          {#if org?.rating_count}· {org.rating_count} Bewertungen{/if}
        </div>
      </div>
    </div>

    <!-- Facts grid -->
    <div class="mx-4 mt-3.5 grid grid-cols-2 gap-2.5">
      {#each facts as f}
        <div class="rounded-xl border border-outline-variant bg-surface p-3">
          <div class="flex items-center gap-2">
            <Icon name={f.icon} size={14} class="text-secondary" />
            <span class="text-[10.5px] font-semibold uppercase tracking-wide text-on-surface-variant">{f.label}</span>
          </div>
          <div class="mt-1.5 text-[13.5px] font-semibold leading-tight text-on-surface">{f.value}</div>
        </div>
      {/each}
    </div>

    <!-- Description -->
    <section class="mx-4 mt-5">
      <h2 class="mb-2 text-[16px] font-bold text-on-secondary-container">Worum geht's?</h2>
      <p class="text-[14px] leading-relaxed text-on-surface">{offer.description}</p>
    </section>

    <!-- Requirements -->
    <section class="mx-4 mt-5">
      <h2 class="mb-2.5 text-[16px] font-bold text-on-secondary-container">Was du brauchst</h2>
      <div class="overflow-hidden rounded-xl border border-outline-variant bg-surface">
        {#each requirements as r, i}
          <div
            class="flex items-center gap-3 px-3.5 py-3 {i < requirements.length - 1 ? 'border-b border-outline-variant' : ''}"
          >
            <span
              class="flex h-[22px] w-[22px] items-center justify-center rounded-full {r.ok ? 'bg-primary text-white' : 'bg-tertiary/20 text-tertiary'}"
            >
              <Icon name={r.ok ? 'check' : 'priority_high'} size={12} />
            </span>
            <span class="flex-1 text-[13.5px] text-on-surface">{r.t}</span>
            {#if !r.ok}<span class="text-[11px] font-semibold text-tertiary">Fehlt</span>{/if}
          </div>
        {/each}
      </div>
    </section>

    <!-- Friends (mock) -->
    {#if meta && meta.friends.length > 0}
      <section class="mx-4 mt-5">
        <h2 class="mb-2.5 text-[16px] font-bold text-on-secondary-container">Wer ist dabei?</h2>
        <div class="flex items-center gap-3 rounded-xl border border-outline-variant bg-surface p-3.5">
          <div class="flex">
            {#each meta.friends.slice(0, 3) as f, i}
              <div
                class="flex h-8 w-8 items-center justify-center rounded-full border-2 border-white text-[12px] font-bold text-white"
                style="background: {['#A4B097', '#B8A57E', '#7A8AB7'][i]}; margin-left: {i === 0 ? 0 : -8}px;"
              >
                {f[0]}
              </div>
            {/each}
          </div>
          <div class="text-[13px] leading-tight text-on-surface">
            <b>{meta.friends.join(' & ')}</b> {meta.friends.length === 1 ? 'ist' : 'sind'} dabei<br />
            <span class="text-[12px] text-on-surface-variant">+ {meta.taken} weitere Helfer:innen</span>
          </div>
        </div>
      </section>
    {/if}

    <!-- Calendar fit banner (mock) -->
    {#if meta}
      <section
        class="mx-4 mt-5 flex items-center gap-3 rounded-xl border p-3.5"
        style="background: {meta.match === 'fits' ? 'rgba(126,143,107,0.12)' : 'rgba(226,148,90,0.12)'};
               border-color: {meta.match === 'fits' ? 'rgba(126,143,107,0.25)' : 'rgba(226,148,90,0.25)'};"
      >
        <Icon name="calendar_today" size={22} class={meta.match === 'fits' ? 'text-secondary' : 'text-tertiary'} />
        <div class="flex-1">
          <div class="text-[13px] font-bold {meta.match === 'fits' ? 'text-secondary' : 'text-tertiary'}">
            {meta.match === 'fits' ? 'Passt in deinen Kalender' : 'Teilweise Überschneidung'}
          </div>
          <div class="mt-0.5 text-[11.5px] text-on-surface-variant">
            {meta.match === 'fits'
              ? 'Du bist an diesem Termin frei. Bei Bewerbung wird der Einsatz eingetragen.'
              : 'Du hast einen privaten Termin, der sich teilweise überschneidet.'}
          </div>
        </div>
      </section>
    {/if}
  </article>

  <!-- Sticky apply bar (above bottom nav on mobile) -->
  <div
    class="fixed inset-x-0 bottom-[72px] z-30 mx-auto flex max-w-2xl items-center gap-2.5 border-t border-outline
           bg-background/96 px-4 py-3.5 backdrop-blur md:bottom-0"
  >
    <button
      type="button"
      onclick={toggleSave}
      aria-label="Merken"
      class="flex h-[52px] w-[52px] items-center justify-center rounded-btn border border-outline-variant bg-surface text-secondary"
    >
      <Icon name="bookmark" filled={saved} size={20} />
    </button>
    <button
      type="button"
      onclick={() => !hasApplied && (showConfirm = true)}
      disabled={hasApplied}
      class="flex flex-1 items-center justify-center rounded-btn px-5 py-[15px] text-[16px] font-semibold text-white
             shadow-[0_4px_14px_rgba(126,143,107,0.35)] {hasApplied ? 'bg-on-surface-variant' : 'bg-primary'}"
    >
      {hasApplied ? '✓ Bewerbung gesendet' : "Jetzt bewerben · +100 P."}
    </button>
  </div>

  <!-- Apply confirmation bottom sheet -->
  {#if showConfirm}
    <div
      class="fixed inset-0 z-[90] flex items-end bg-black/55"
      role="button"
      tabindex="-1"
      onclick={(e) => e.target === e.currentTarget && (showConfirm = false)}
      onkeydown={(e) => e.key === 'Escape' && (showConfirm = false)}
    >
      <div class="animate-slide-up w-full rounded-t-3xl bg-surface px-[22px] pb-8 pt-3.5">
        <div class="mx-auto mb-4 h-1 w-10 rounded-full bg-outline"></div>
        <div class="mx-auto mb-3.5 mt-1.5 flex h-16 w-16 items-center justify-center rounded-full bg-primary/15">
          <Icon name="favorite" filled size={28} class="text-primary" />
        </div>
        <div class="text-center text-[22px] font-bold tracking-tight text-on-secondary-container">
          Bewerbung absenden?
        </div>
        <div class="mt-2 text-center text-[14px] leading-relaxed text-on-surface-variant">
          Dein Profil wird an <b>{org?.display_name ?? 'die Organisation'}</b> übermittelt. Du erhältst
          eine Bestätigung.
        </div>

        <div class="mt-4 flex items-center gap-3 rounded-xl border border-outline-variant bg-surface-variant p-3">
          <div class="flex h-9 w-9 items-center justify-center rounded-full bg-primary-container text-[12px] font-bold text-white">
            {(auth.profile?.display_name ?? 'Du')
              .split(' ')
              .map((w) => w[0])
              .slice(0, 2)
              .join('')}
          </div>
          <div class="min-w-0 flex-1">
            <div class="text-[13.5px] font-semibold text-on-surface">{auth.profile?.display_name ?? 'Du'}</div>
            <div class="mt-0.5 text-[11.5px] text-on-surface-variant">Verifiziert · Helfer:in</div>
          </div>
          <Icon name="verified" filled size={18} class="text-primary" />
        </div>

        <div class="mt-4 flex flex-col gap-2">
          <button
            type="button"
            onclick={confirmApply}
            disabled={applying}
            class="flex items-center justify-center rounded-btn bg-primary px-5 py-[15px] text-[16px] font-semibold text-white
                   shadow-[0_4px_14px_rgba(126,143,107,0.35)] disabled:opacity-60"
          >
            {applying ? 'Wird gesendet …' : 'Ja, bewerben'}
          </button>
          <button
            type="button"
            onclick={() => (showConfirm = false)}
            class="py-3 text-[14px] font-medium text-on-surface-variant"
          >
            Abbrechen
          </button>
        </div>
      </div>
    </div>
  {/if}
{/if}

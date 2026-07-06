<script lang="ts">
  import { goto } from '$app/navigation';
  import PageHeader from '$lib/components/layout/PageHeader.svelte';
  import TextField from '$lib/components/forms/TextField.svelte';
  import TextArea from '$lib/components/forms/TextArea.svelte';
  import Select from '$lib/components/forms/Select.svelte';
  import Checkbox from '$lib/components/forms/Checkbox.svelte';
  import DatePicker from '$lib/components/forms/DatePicker.svelte';
  import TimePicker from '$lib/components/forms/TimePicker.svelte';
  import TagInput from '$lib/components/forms/TagInput.svelte';
  import FormSection from '$lib/components/forms/FormSection.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Alert from '$lib/components/ui/Alert.svelte';
  import OfferPreviewCard from '$lib/features/offers/components/OfferPreviewCard.svelte';
  import { createOffer, publishOffer } from '$lib/services/supabase/offers';
  import { auth } from '$lib/stores/auth.svelte';
  import { toasts } from '$lib/stores/toasts.svelte';
  import { offerSchema } from '$lib/validation/offer';
  import type { OfferType } from '$lib/types/database';

  let title = $state('');
  let description = $state('');
  let offer_type = $state<OfferType>('single_event');
  let city = $state('');
  let is_remote = $state(false);
  let startDate = $state('');
  let startTime = $state('');
  let endDate = $state('');
  let endTime = $state('');
  let skills = $state<string[]>([]);
  let max_helpers = $state<number | ''>('');
  let saving = $state(false);
  let error = $state<string | null>(null);

  function buildIso(d: string, t: string): string | null {
    if (!d) return null;
    return new Date(`${d}T${t || '00:00'}`).toISOString();
  }

  async function save(publish: boolean) {
    if (!auth.profile) return;
    error = null;
    const payload = {
      title,
      description,
      offer_type,
      city: is_remote ? null : city,
      is_remote,
      starts_at: buildIso(startDate, startTime),
      ends_at: buildIso(endDate, endTime),
      skills_required: skills,
      max_helpers: max_helpers === '' ? null : Number(max_helpers),
    };
    const parsed = offerSchema.safeParse(payload);
    if (!parsed.success) {
      error = parsed.error.issues[0]?.message ?? 'Ungültige Eingabe';
      return;
    }
    saving = true;
    try {
      const created = await createOffer({
        ...parsed.data,
        organization_profile_id: auth.profile.id,
      });
      if (publish) await publishOffer(created.id);
      toasts.success(publish ? 'Angebot veröffentlicht' : 'Entwurf gespeichert');
      await goto('/offers');
    } catch (err) {
      error = err instanceof Error ? err.message : 'Speichern fehlgeschlagen';
    } finally {
      saving = false;
    }
  }
</script>

<svelte:head><title>Neues Angebot · ActNow</title></svelte:head>

<section class="grid grid-cols-1 gap-md p-md lg:grid-cols-[1fr_320px]">
  <div class="flex flex-col gap-md">
    <PageHeader title="Neues Angebot" subtitle="Beschreibe, wen du suchst und wofür." />

    {#if error}
      <Alert tone="error">{error}</Alert>
    {/if}

    <FormSection title="Grunddaten">
      <TextField label="Titel" required bind:value={title} />
      <TextArea label="Beschreibung" required rows={5} bind:value={description} />
      <Select label="Art" bind:value={offer_type}>
        <option value="single_event">Einmaliges Event</option>
        <option value="recurring_event">Regelmäßig</option>
        <option value="flexible_task">Flexible Aufgabe</option>
        <option value="digital_task">Digitale Aufgabe</option>
      </Select>
    </FormSection>

    <FormSection title="Ort">
      <Checkbox label="Digital / Remote" bind:checked={is_remote} />
      {#if !is_remote}
        <TextField label="Stadt" bind:value={city} />
      {/if}
    </FormSection>

    <FormSection title="Zeitraum">
      <div class="grid grid-cols-2 gap-sm">
        <DatePicker label="Beginn (Datum)" bind:value={startDate} />
        <TimePicker label="Beginn (Uhrzeit)" bind:value={startTime} />
        <DatePicker label="Ende (Datum)" bind:value={endDate} />
        <TimePicker label="Ende (Uhrzeit)" bind:value={endTime} />
      </div>
    </FormSection>

    <FormSection title="Helfer">
      <TextField type="number" label="Max. Helfer (optional)" bind:value={max_helpers} />
      <TagInput label="Benötigte Skills" bind:value={skills} />
    </FormSection>

    <div class="flex justify-end gap-sm">
      <Button variant="outlined" disabled={saving} onclick={() => save(false)}>
        Als Entwurf speichern
      </Button>
      <Button disabled={saving} onclick={() => save(true)}>Veröffentlichen</Button>
    </div>
  </div>

  <div class="lg:sticky lg:top-md lg:self-start">
    <OfferPreviewCard
      offer={{
        title,
        description,
        organization_name: auth.profile?.display_name,
        organization_avatar_url: auth.profile?.avatar_url ?? null,
        organization_rating: auth.profile?.average_rating ?? null,
        is_remote,
        city,
        starts_at: buildIso(startDate, startTime),
      }}
    />
  </div>
</section>

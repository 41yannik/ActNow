<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { OfferStatus, ApplicationStatus } from '$lib/types/domain';

  type Tone = 'neutral' | 'success' | 'warning' | 'danger' | 'info' | 'muted';
  interface Props {
    tone?: Tone;
    /** Optional auto-mapping from an offer / application status enum. */
    status?: OfferStatus | ApplicationStatus;
    class?: string;
    children?: Snippet;
  }
  let { tone, status, class: klass = '', children }: Props = $props();

  // Map enum -> tone. Keep aligned with docs/schema.sql.
  const statusToneMap: Record<string, Tone> = {
    // offer_status
    draft: 'muted',
    published: 'success',
    paused: 'warning',
    filled: 'info',
    completed: 'info',
    cancelled: 'danger',
    archived: 'muted',
    // application_status
    submitted: 'info',
    shortlisted: 'warning',
    accepted: 'success',
    rejected: 'danger',
    withdrawn: 'muted',
    no_show: 'danger',
  };

  const effective: Tone = $derived(
    tone ?? (status ? (statusToneMap[status] ?? 'neutral') : 'neutral'),
  );

  const tones: Record<Tone, string> = {
    neutral: 'bg-surface-container text-on-surface',
    success: 'bg-tertiary-fixed text-on-tertiary-fixed',
    warning: 'bg-secondary-container text-on-secondary-container',
    danger: 'bg-error-container text-on-error-container',
    info: 'bg-secondary-container text-on-secondary-container',
    muted: 'bg-surface-variant text-on-surface-variant',
  };
</script>

<span
  class="inline-flex items-center px-2 py-1 rounded-full font-label-md text-[12px] {tones[
    effective
  ]} {klass}"
>
  {#if children}{@render children()}{:else}{status}{/if}
</span>

<script lang="ts">
  // Applicant card on offer detail / applications page.
  import type { ApplicationRow, HelperProfileRow, ProfileRow } from '$lib/types/database';
  import Avatar from '$lib/components/ui/Avatar.svelte';
  import Badge from '$lib/components/ui/Badge.svelte';
  import Button from '$lib/components/ui/Button.svelte';
  import Tag from '$lib/components/ui/Tag.svelte';
  import { APPLICATION_STATUS_LABEL } from '$lib/utils/labels';
  import { formatRelative } from '$lib/utils/format';

  export interface ApplicantView {
    application: ApplicationRow;
    profile: Pick<ProfileRow, 'id' | 'display_name' | 'avatar_url' | 'city' | 'average_rating'>;
    helper?: Pick<HelperProfileRow, 'skills' | 'languages'> | null;
  }

  interface Props {
    applicant: ApplicantView;
    onaccept?: (id: string) => void;
    onreject?: (id: string) => void;
    onmessage?: (id: string) => void;
    onview?: (id: string) => void;
    class?: string;
  }
  const { applicant, onaccept, onreject, onmessage, onview, class: klass = '' }: Props = $props();

  const a = $derived(applicant.application);
  const p = $derived(applicant.profile);
  const skills = $derived(applicant.helper?.skills ?? []);
  const pending = $derived(a.status === 'submitted' || a.status === 'shortlisted');
</script>

<article
  class="flex flex-col gap-sm rounded-2xl border border-outline-variant bg-surface-container-lowest p-md {klass}"
>
  <header class="flex items-start gap-sm">
    <button
      type="button"
      class="shrink-0"
      onclick={() => onview?.(p.id)}
      aria-label="Profil ansehen"
    >
      <Avatar src={p.avatar_url} name={p.display_name} size="md" />
    </button>
    <div class="min-w-0 flex-1">
      <h3 class="font-h4 text-h4 truncate text-on-surface">{p.display_name}</h3>
      <p class="text-label-md font-label-md text-on-surface-variant">
        {p.city ?? ''} · beworben {formatRelative(a.submitted_at)}
      </p>
    </div>
    <Badge status={a.status}>{APPLICATION_STATUS_LABEL[a.status]}</Badge>
  </header>

  {#if a.motivation_text}
    <p class="text-body-md font-body-md line-clamp-3 text-on-surface">{a.motivation_text}</p>
  {/if}

  {#if skills.length}
    <div class="flex flex-wrap gap-1">
      {#each skills.slice(0, 5) as s}
        <Tag label={s} />
      {/each}
    </div>
  {/if}

  <div class="flex flex-wrap items-center justify-end gap-xs">
    <Button variant="text" leadingIcon="chat" onclick={() => onmessage?.(a.id)}>Nachricht</Button>
    {#if pending}
      <Button variant="outlined" leadingIcon="close" onclick={() => onreject?.(a.id)}
        >Ablehnen</Button
      >
      <Button variant="primary" leadingIcon="check" onclick={() => onaccept?.(a.id)}
        >Annehmen</Button
      >
    {/if}
  </div>
</article>

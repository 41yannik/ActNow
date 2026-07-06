<script lang="ts">
  // Inline-editable field with edit/save/cancel.
  import IconButton from '$lib/components/ui/IconButton.svelte';
  import TextField from '$lib/components/forms/TextField.svelte';
  import TextArea from '$lib/components/forms/TextArea.svelte';

  interface Props {
    label: string;
    value: string;
    multiline?: boolean;
    placeholder?: string;
    onsave: (next: string) => void | Promise<void>;
    class?: string;
  }
  const {
    label,
    value,
    multiline = false,
    placeholder = '',
    onsave,
    class: klass = '',
  }: Props = $props();

  let editing = $state(false);
  let draft = $state('');
  let saving = $state(false);

  $effect(() => {
    if (!editing) draft = value;
  });

  function startEdit() {
    draft = value;
    editing = true;
  }
  function cancel() {
    editing = false;
  }
  async function save() {
    saving = true;
    try {
      await onsave(draft);
      editing = false;
    } finally {
      saving = false;
    }
  }
</script>

<div class="flex flex-col gap-xs {klass}">
  <div class="flex items-center justify-between">
    <span class="text-label-md font-label-md text-on-surface-variant">{label}</span>
    {#if !editing}
      <IconButton icon="edit" label="Bearbeiten" size="sm" onclick={startEdit} />
    {/if}
  </div>
  {#if editing}
    {#if multiline}
      <TextArea bind:value={draft} {placeholder} rows={4} />
    {:else}
      <TextField bind:value={draft} {placeholder} />
    {/if}
    <div class="flex justify-end gap-xs">
      <button type="button" class="px-sm py-1 text-on-surface-variant" onclick={cancel}
        >Abbrechen</button
      >
      <button
        type="button"
        class="rounded-full bg-primary px-md py-1 text-on-primary disabled:opacity-50"
        disabled={saving}
        onclick={save}
      >
        Speichern
      </button>
    </div>
  {:else}
    <p class="text-body-md font-body-md whitespace-pre-wrap text-on-surface">
      {value || placeholder || '—'}
    </p>
  {/if}
</div>

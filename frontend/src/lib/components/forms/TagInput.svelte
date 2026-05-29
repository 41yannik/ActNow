<script lang="ts">
  import Icon from '../ui/Icon.svelte';

  interface Props {
    label?: string;
    helper?: string;
    error?: string | null;
    value?: string[];
    placeholder?: string;
    /** Optional autocomplete suggestions filtered by current input. */
    suggestions?: string[];
    id?: string;
    class?: string;
  }
  let {
    label,
    helper,
    error = null,
    value = $bindable([]),
    placeholder = 'Hinzufügen…',
    suggestions = [],
    id,
    class: klass = ''
  }: Props = $props();

  let draft = $state('');
  const inputId = $derived(id ?? `tagi-${Math.random().toString(36).slice(2, 9)}`);
  const filteredSuggestions = $derived(
    draft.trim().length === 0
      ? []
      : suggestions
          .filter(
            (s) =>
              s.toLowerCase().includes(draft.toLowerCase()) &&
              !value.includes(s)
          )
          .slice(0, 6)
  );

  function add(tag: string) {
    const trimmed = tag.trim();
    if (!trimmed || value.includes(trimmed)) return;
    value = [...value, trimmed];
    draft = '';
  }

  function remove(tag: string) {
    value = value.filter((t) => t !== tag);
  }

  function onKeyDown(e: KeyboardEvent) {
    if (e.key === 'Enter' || e.key === ',') {
      e.preventDefault();
      if (draft.trim()) add(draft);
    } else if (e.key === 'Backspace' && draft === '' && value.length > 0) {
      remove(value[value.length - 1]);
    }
  }
</script>

<div class="w-full {klass}">
  {#if label}
    <label for={inputId} class="block font-label-md text-label-md text-on-surface-variant mb-1">
      {label}
    </label>
  {/if}
  <div
    class="flex flex-wrap items-center gap-xs rounded-lg border bg-surface px-sm py-2 transition-shadow focus-within:ring-2 focus-within:ring-primary focus-within:border-primary {error ? 'border-error' : 'border-outline-variant'}"
  >
    {#each value as tag}
      <span
        class="inline-flex items-center gap-1 rounded-full bg-secondary-container px-sm py-1 font-label-md text-label-md text-on-secondary-container"
      >
        {tag}
        <button
          type="button"
          aria-label="Entfernen: {tag}"
          class="ml-0.5 inline-flex h-4 w-4 items-center justify-center rounded-full hover:bg-on-secondary-container/10"
          onclick={() => remove(tag)}
        >
          <Icon name="close" size={14} />
        </button>
      </span>
    {/each}
    <input
      id={inputId}
      type="text"
      class="min-w-[8ch] flex-1 bg-transparent py-1 outline-none placeholder:text-on-surface-variant"
      placeholder={value.length === 0 ? placeholder : ''}
      bind:value={draft}
      onkeydown={onKeyDown}
    />
  </div>
  {#if filteredSuggestions.length > 0}
    <ul
      class="mt-1 max-h-40 overflow-y-auto rounded-lg border border-outline-variant bg-surface py-1 shadow"
    >
      {#each filteredSuggestions as s}
        <li>
          <button
            type="button"
            class="w-full px-sm py-1 text-left font-body-md text-body-md hover:bg-surface-container-low"
            onclick={() => add(s)}
          >
            {s}
          </button>
        </li>
      {/each}
    </ul>
  {/if}
  {#if error}
    <p class="mt-1 text-[13px] text-error font-label-md">{error}</p>
  {:else if helper}
    <p class="mt-1 text-[13px] text-on-surface-variant">{helper}</p>
  {/if}
</div>

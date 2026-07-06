<script lang="ts">
  import type { HTMLTextareaAttributes } from 'svelte/elements';

  interface Props extends Omit<HTMLTextareaAttributes, 'class' | 'value'> {
    label?: string;
    helper?: string;
    error?: string | null;
    value?: string;
    class?: string;
  }
  let {
    label,
    helper,
    error = null,
    value = $bindable(''),
    rows = 5,
    id,
    class: klass = '',
    ...rest
  }: Props = $props();

  const ta = $derived(id ?? `ta-${Math.random().toString(36).slice(2, 9)}`);
</script>

<div class="w-full {klass}">
  {#if label}
    <label for={ta} class="block font-label-md text-label-md text-on-surface-variant mb-1"
      >{label}</label
    >
  {/if}
  <textarea
    id={ta}
    bind:value
    {rows}
    class="
      w-full bg-surface border rounded-lg px-sm py-sm text-on-surface
      font-body-md text-body-md transition-shadow
      focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary
      {error ? 'border-error focus:ring-error focus:border-error' : 'border-outline-variant'}
    "
    aria-invalid={error ? 'true' : undefined}
    {...rest}
  ></textarea>
  {#if error}
    <p class="mt-1 text-[13px] text-error font-label-md">{error}</p>
  {:else if helper}
    <p class="mt-1 text-[13px] text-on-surface-variant">{helper}</p>
  {/if}
</div>

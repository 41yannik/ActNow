<script lang="ts">
  import type { HTMLInputAttributes } from 'svelte/elements';
  import Icon from '../ui/Icon.svelte';

  interface Props extends Omit<HTMLInputAttributes, 'class' | 'type' | 'value'> {
    label?: string;
    helper?: string;
    error?: string | null;
    leadingIcon?: string;
    trailingIcon?: string;
    type?: 'text' | 'email' | 'password' | 'tel' | 'url' | 'number' | 'search' | 'date' | 'time';
    value?: string | number;
    class?: string;
  }
  let {
    label,
    helper,
    error = null,
    leadingIcon,
    trailingIcon,
    type = 'text',
    value = $bindable(''),
    id,
    class: klass = '',
    ...rest
  }: Props = $props();

  const inputId = $derived(id ?? `tf-${Math.random().toString(36).slice(2, 9)}`);
</script>

<div class="w-full {klass}">
  {#if label}
    <label
      for={inputId}
      class="block font-label-md text-label-md text-on-surface-variant mb-1"
    >
      {label}
    </label>
  {/if}
  <div class="relative">
    {#if leadingIcon}
      <span class="absolute left-sm top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none">
        <Icon name={leadingIcon} size={20} />
      </span>
    {/if}
    <input
      id={inputId}
      {type}
      bind:value
      class="
        w-full bg-surface border rounded-lg py-sm text-on-surface
        font-body-md text-body-md transition-shadow
        focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary
        {leadingIcon ? 'pl-10' : 'pl-sm'} {trailingIcon ? 'pr-10' : 'pr-sm'}
        {error ? 'border-error focus:ring-error focus:border-error' : 'border-outline-variant'}
      "
      aria-invalid={error ? 'true' : undefined}
      aria-describedby={error || helper ? `${inputId}-msg` : undefined}
      {...rest}
    />
    {#if trailingIcon}
      <span class="absolute right-sm top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none">
        <Icon name={trailingIcon} size={20} />
      </span>
    {/if}
  </div>
  {#if error}
    <p id="{inputId}-msg" class="mt-1 text-[13px] text-error font-label-md">{error}</p>
  {:else if helper}
    <p id="{inputId}-msg" class="mt-1 text-[13px] text-on-surface-variant">{helper}</p>
  {/if}
</div>

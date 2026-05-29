<script lang="ts">
  import type { HTMLInputAttributes } from 'svelte/elements';
  import Icon from '../ui/Icon.svelte';
  import IconButton from '../ui/IconButton.svelte';

  interface Props extends Omit<HTMLInputAttributes, 'class' | 'type' | 'value'> {
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
    id,
    class: klass = '',
    ...rest
  }: Props = $props();

  let visible = $state(false);
  const inputId = $derived(id ?? `pw-${Math.random().toString(36).slice(2, 9)}`);
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
    <span
      class="absolute left-sm top-1/2 -translate-y-1/2 text-on-surface-variant pointer-events-none"
    >
      <Icon name="lock" size={20} />
    </span>
    <input
      id={inputId}
      type={visible ? 'text' : 'password'}
      bind:value
      class="
        w-full bg-surface border rounded-lg py-sm pl-10 pr-12 text-on-surface
        font-body-md text-body-md transition-shadow
        focus:outline-none focus:ring-2 focus:ring-primary focus:border-primary
        {error ? 'border-error focus:ring-error focus:border-error' : 'border-outline-variant'}
      "
      aria-invalid={error ? 'true' : undefined}
      aria-describedby={error || helper ? `${inputId}-msg` : undefined}
      {...rest}
    />
    <div class="absolute right-1 top-1/2 -translate-y-1/2">
      <IconButton
        icon={visible ? 'visibility_off' : 'visibility'}
        label={visible ? 'Passwort verbergen' : 'Passwort anzeigen'}
        size="sm"
        onclick={() => (visible = !visible)}
      />
    </div>
  </div>
  {#if error}
    <p id="{inputId}-msg" class="mt-1 text-[13px] text-error font-label-md">{error}</p>
  {:else if helper}
    <p id="{inputId}-msg" class="mt-1 text-[13px] text-on-surface-variant">{helper}</p>
  {/if}
</div>

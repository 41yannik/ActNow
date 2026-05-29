<script lang="ts">
  import type { HTMLButtonAttributes } from 'svelte/elements';
  import Icon from './Icon.svelte';

  type Tone = 'default' | 'primary' | 'danger' | 'success';
  type Size = 'sm' | 'md' | 'lg';

  interface Props extends Omit<HTMLButtonAttributes, 'class'> {
    icon: string;
    filled?: boolean;
    label: string; // accessible name (required, visually hidden)
    tone?: Tone;
    size?: Size;
    class?: string;
  }
  let {
    icon,
    filled = false,
    label,
    tone = 'default',
    size = 'md',
    type = 'button',
    class: klass = '',
    ...rest
  }: Props = $props();

  const tones: Record<Tone, string> = {
    default: 'text-on-surface-variant hover:text-primary hover:bg-surface-container',
    primary: 'text-primary hover:bg-primary/10',
    danger: 'text-error hover:bg-error-container',
    success: 'text-primary hover:bg-tertiary-fixed'
  };
  const sizes: Record<Size, { wrap: string; icon: number }> = {
    sm: { wrap: 'p-1.5', icon: 18 },
    md: { wrap: 'p-2', icon: 22 },
    lg: { wrap: 'p-3', icon: 28 }
  };
</script>

<button
  {type}
  aria-label={label}
  class="
    inline-flex items-center justify-center rounded-full transition-colors active:scale-95
    disabled:opacity-50 disabled:cursor-not-allowed
    {tones[tone]} {sizes[size].wrap} {klass}
  "
  {...rest}
>
  <Icon name={icon} {filled} size={sizes[size].icon} />
</button>

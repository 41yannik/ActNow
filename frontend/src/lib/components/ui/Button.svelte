<script lang="ts">
  import type { Snippet } from 'svelte';
  import type { HTMLButtonAttributes } from 'svelte/elements';
  import Icon from './Icon.svelte';

  type Variant = 'primary' | 'secondary' | 'outlined' | 'text' | 'danger';
  type Size = 'sm' | 'md' | 'lg';

  interface Props extends Omit<HTMLButtonAttributes, 'class'> {
    variant?: Variant;
    size?: Size;
    loading?: boolean;
    leadingIcon?: string;
    trailingIcon?: string;
    /** Full-width on small screens (block w-full). */
    block?: boolean;
    class?: string;
    children?: Snippet;
  }
  let {
    variant = 'primary',
    size = 'md',
    loading = false,
    leadingIcon,
    trailingIcon,
    block = false,
    type = 'button',
    disabled,
    class: klass = '',
    children,
    ...rest
  }: Props = $props();

  const variants: Record<Variant, string> = {
    primary:
      'bg-primary text-on-primary hover:bg-primary-container shadow-[0px_4px_20px_rgba(47,79,79,0.08)] hover:shadow-[0px_8px_30px_rgba(47,79,79,0.12)]',
    secondary:
      'bg-secondary-container text-on-secondary-container hover:bg-secondary hover:text-on-secondary',
    outlined:
      'border border-outline text-on-surface hover:bg-surface-container-low',
    text: 'text-primary hover:bg-surface-container-low',
    danger:
      'bg-error text-on-error hover:bg-error-container hover:text-on-error-container'
  };
  const sizes: Record<Size, string> = {
    sm: 'px-sm py-1 text-[13px]',
    md: 'px-md py-sm font-label-md text-label-md',
    lg: 'px-md py-3 text-body-md'
  };
</script>

<button
  {type}
  disabled={disabled || loading}
  class="
    inline-flex items-center justify-center gap-xs rounded-full transition-colors
    disabled:opacity-50 disabled:cursor-not-allowed active:scale-[0.98]
    {variants[variant]} {sizes[size]} {block ? 'w-full' : ''} {klass}
  "
  {...rest}
>
  {#if loading}
    <Icon name="progress_activity" size={size === 'sm' ? 16 : 18} class="animate-spin" />
  {:else if leadingIcon}
    <Icon name={leadingIcon} size={size === 'sm' ? 16 : 18} />
  {/if}
  {#if children}{@render children()}{/if}
  {#if trailingIcon && !loading}
    <Icon name={trailingIcon} size={size === 'sm' ? 16 : 18} />
  {/if}
</button>

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
      'bg-primary text-on-primary hover:bg-secondary shadow-[0_4px_14px_rgba(126,143,107,0.35)] hover:shadow-[0_8px_20px_rgba(126,143,107,0.5)]',
    secondary:
      'bg-secondary-container text-on-secondary-container hover:bg-secondary hover:text-on-secondary',
    outlined: 'border border-secondary text-secondary hover:bg-secondary-container/20',
    text: 'text-primary hover:bg-primary-container/10',
    danger: 'bg-error text-on-error hover:bg-error-container hover:text-on-error-container',
  };
  const sizes: Record<Size, string> = {
    sm: 'px-sm py-1.5 text-[13px]',
    md: 'px-md py-[11px] font-label-md text-label-md',
    lg: 'px-[22px] py-[15px] text-body-md',
  };
</script>

<button
  {type}
  disabled={disabled || loading}
  class="
    inline-flex items-center justify-center gap-xs rounded-btn transition-all
    disabled:opacity-50 disabled:cursor-not-allowed active:scale-[0.97]
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

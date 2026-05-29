<script lang="ts">
  import type { Snippet } from 'svelte';
  import IconButton from './IconButton.svelte';

  interface Props {
    open: boolean;
    title?: string;
    /** Optional max-width override (Tailwind class). Defaults to 'max-w-lg'. */
    size?: 'sm' | 'md' | 'lg' | 'xl';
    /** When false (default) clicking the backdrop closes the modal. */
    persistent?: boolean;
    onclose?: () => void;
    children?: Snippet;
    footer?: Snippet;
  }

  let {
    open = $bindable(),
    title,
    size = 'md',
    persistent = false,
    onclose,
    children,
    footer
  }: Props = $props();

  const sizes: Record<NonNullable<Props['size']>, string> = {
    sm: 'max-w-sm',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl'
  };

  function close() {
    open = false;
    onclose?.();
  }

  function onBackdropClick(e: MouseEvent) {
    if (persistent) return;
    if (e.target === e.currentTarget) close();
  }

  function onKey(e: KeyboardEvent) {
    if (e.key === 'Escape' && !persistent) close();
  }
</script>

{#if open}
  <div
    class="fixed inset-0 z-[90] flex items-center justify-center bg-black/40 p-sm"
    role="dialog"
    aria-modal="true"
    aria-label={title ?? 'Dialog'}
    tabindex="-1"
    onclick={onBackdropClick}
    onkeydown={onKey}
  >
    <div
      class="w-full {sizes[size]} max-h-[90vh] overflow-hidden rounded-2xl bg-surface text-on-surface shadow-2xl"
      role="document"
    >
      {#if title}
        <header class="flex items-center justify-between border-b border-outline-variant px-md py-sm">
          <h2 class="font-h3 text-h3 text-on-surface">{title}</h2>
          <IconButton icon="close" label="Schließen" onclick={close} />
        </header>
      {/if}
      <div class="overflow-y-auto px-md py-md" style="max-height: calc(90vh - 8rem);">
        {#if children}{@render children()}{/if}
      </div>
      {#if footer}
        <footer class="flex items-center justify-end gap-sm border-t border-outline-variant px-md py-sm">
          {@render footer()}
        </footer>
      {/if}
    </div>
  </div>
{/if}

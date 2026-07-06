<script lang="ts">
  import type { Snippet } from 'svelte';
  import IconButton from './IconButton.svelte';

  interface Props {
    /** Triggering element snippet — typically an IconButton. Receives a `toggle` callback. */
    trigger?: Snippet<[() => void, boolean]>;
    /** Icon name shorthand when no custom trigger is supplied. */
    icon?: string;
    label?: string;
    /** Alignment of the dropdown menu relative to trigger. */
    align?: 'left' | 'right';
    children?: Snippet<[() => void]>;
    class?: string;
  }

  let {
    trigger,
    icon = 'more_vert',
    label = 'Menü',
    align = 'right',
    children,
    class: klass = '',
  }: Props = $props();

  let open = $state(false);
  let wrapper: HTMLDivElement | undefined = $state();

  function toggle() {
    open = !open;
  }

  function close() {
    open = false;
  }

  function onDocClick(e: MouseEvent) {
    if (!open || !wrapper) return;
    if (!wrapper.contains(e.target as Node)) close();
  }

  function onKey(e: KeyboardEvent) {
    if (e.key === 'Escape') close();
  }

  $effect(() => {
    if (!open) return;
    document.addEventListener('click', onDocClick);
    document.addEventListener('keydown', onKey);
    return () => {
      document.removeEventListener('click', onDocClick);
      document.removeEventListener('keydown', onKey);
    };
  });
</script>

<div class="relative inline-block {klass}" bind:this={wrapper}>
  {#if trigger}
    {@render trigger(toggle, open)}
  {:else}
    <IconButton {icon} {label} onclick={toggle} />
  {/if}

  {#if open}
    <div
      class="absolute z-50 mt-1 min-w-[180px] overflow-hidden rounded-lg border border-outline-variant bg-surface py-1 shadow-lg {align ===
      'right'
        ? 'right-0'
        : 'left-0'}"
      role="menu"
    >
      {#if children}{@render children(close)}{/if}
    </div>
  {/if}
</div>

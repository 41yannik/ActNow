<script lang="ts">
  // Square rounded org-logo tile with initials fallback.
  // Used on the swipe card overlap + offer preview.
  type Size = 'sm' | 'md' | 'lg';
  interface Props {
    src?: string | null;
    name: string;
    size?: Size;
    class?: string;
  }
  let { src, name, size = 'md', class: klass = '' }: Props = $props();

  const sizes: Record<Size, string> = {
    sm: 'w-10 h-10 text-sm',
    md: 'w-14 h-14 text-base',
    lg: 'w-16 h-16 text-lg',
  };

  const initials = $derived(
    name
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((w) => w[0]?.toUpperCase() ?? '')
      .join('') || '?',
  );
</script>

<span
  class="
    inline-flex items-center justify-center
    bg-surface-container-lowest rounded-xl shadow-md p-1
    border border-surface-container-low {klass}
  "
>
  {#if src}
    <img
      {src}
      alt={name}
      class="rounded-lg object-cover w-full h-full {sizes[size]}"
      loading="lazy"
    />
  {:else}
    <span
      class="rounded-lg bg-primary-container text-on-primary-container
             flex items-center justify-center font-h3 w-full h-full {sizes[size]}"
    >
      {initials}
    </span>
  {/if}
</span>

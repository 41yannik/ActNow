<script lang="ts">
  type Size = 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  interface Props {
    src?: string | null;
    alt?: string;
    name?: string; // used to derive initials when src is missing
    size?: Size;
    status?: 'online' | 'offline' | 'busy' | null;
    class?: string;
  }
  let {
    src,
    alt = '',
    name = '',
    size = 'md',
    status = null,
    class: klass = ''
  }: Props = $props();

  const sizes: Record<Size, string> = {
    xs: 'w-6 h-6 text-[10px]',
    sm: 'w-8 h-8 text-xs',
    md: 'w-10 h-10 text-sm',
    lg: 'w-14 h-14 text-base',
    xl: 'w-20 h-20 text-lg'
  };
  const statusColor: Record<NonNullable<Props['status']>, string> = {
    online: 'bg-primary',
    offline: 'bg-outline',
    busy: 'bg-error'
  };

  const initials = $derived(
    name
      .trim()
      .split(/\s+/)
      .slice(0, 2)
      .map((w) => w[0]?.toUpperCase() ?? '')
      .join('') || '?'
  );
</script>

<span class="relative inline-flex shrink-0 {klass}">
  {#if src}
    <img
      {src}
      alt={alt || name}
      class="rounded-full object-cover shadow-sm {sizes[size]}"
      loading="lazy"
    />
  {:else}
    <span
      class="rounded-full bg-secondary-container text-on-secondary-container
             flex items-center justify-center font-h3 {sizes[size]}"
      aria-label={alt || name}
    >
      {initials}
    </span>
  {/if}
  {#if status}
    <span
      class="absolute bottom-0 right-0 w-2.5 h-2.5 rounded-full ring-2 ring-surface {statusColor[status]}"
      aria-hidden="true"
    ></span>
  {/if}
</span>

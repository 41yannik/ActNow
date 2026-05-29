<script lang="ts">
  interface Props {
    /** Shape: rectangle/text/circle. */
    variant?: 'rect' | 'text' | 'circle';
    /** Tailwind width/height utility classes. */
    class?: string;
    /** Number of stacked lines for `variant="text"`. */
    lines?: number;
  }
  const { variant = 'rect', class: klass = '', lines = 1 }: Props = $props();

  const base =
    'animate-pulse bg-surface-container-high';
  const shape = {
    rect: 'rounded-lg',
    text: 'rounded h-4',
    circle: 'rounded-full'
  } as const;
</script>

{#if variant === 'text' && lines > 1}
  <div class="space-y-2 {klass}">
    {#each Array(lines) as _, i}
      <div
        class="{base} {shape.text}"
        style="width: {i === lines - 1 ? 60 : 100}%"
      ></div>
    {/each}
  </div>
{:else}
  <div class="{base} {shape[variant]} {klass}"></div>
{/if}

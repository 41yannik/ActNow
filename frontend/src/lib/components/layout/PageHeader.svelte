<script lang="ts">
  import type { Snippet } from 'svelte';
  interface Props {
    title: string;
    subtitle?: string;
    action?: Snippet;
    class?: string;
  }
  let { title, subtitle, action, class: klass = '' }: Props = $props();
</script>

<header class="flex flex-col md:flex-row md:items-end justify-between gap-md mb-lg {klass}">
  <div>
    <h1 class="font-h1-mobile text-h1-mobile md:font-h1 md:text-h1 text-on-surface mb-xs">
      {title}
    </h1>
    {#if subtitle}
      <p class="font-body-lg text-body-lg text-on-surface-variant">{subtitle}</p>
    {/if}
  </div>
  {#if action}<div class="shrink-0">{@render action()}</div>{/if}
</header>

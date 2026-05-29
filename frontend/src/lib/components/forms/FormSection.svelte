<script lang="ts">
  import type { Snippet } from 'svelte';
  interface Props {
    title: string;
    description?: string;
    class?: string;
    children?: Snippet;
  }
  let { title, description, class: klass = '', children }: Props = $props();
</script>

<section class="space-y-md {klass}">
  <header class="border-b border-outline-variant pb-2">
    <h3 class="font-h3 text-h3 text-on-surface">{title}</h3>
    {#if description}
      <p class="text-[13px] text-on-surface-variant mt-1">{description}</p>
    {/if}
  </header>
  {#if children}{@render children()}{/if}
</section>

<script lang="ts">
  import type { Snippet } from 'svelte';
  import Icon from './Icon.svelte';
  interface Props {
    icon?: string;
    title: string;
    description?: string;
    action?: Snippet;
    class?: string;
  }
  let { icon = 'inbox', title, description, action, class: klass = '' }: Props = $props();
</script>

<div class="flex flex-col items-center justify-center text-center px-md py-lg {klass}">
  <span
    class="w-16 h-16 rounded-full bg-surface-container flex items-center justify-center mb-md text-on-surface-variant"
  >
    <Icon name={icon} size={32} />
  </span>
  <h3 class="font-h3 text-h3 text-on-surface mb-xs">{title}</h3>
  {#if description}
    <p class="font-body-md text-body-md text-on-surface-variant max-w-md">{description}</p>
  {/if}
  {#if action}
    <div class="mt-md">{@render action()}</div>
  {/if}
</div>

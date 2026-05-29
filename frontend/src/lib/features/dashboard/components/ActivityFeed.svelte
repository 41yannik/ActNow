<script lang="ts">
  import type { Snippet } from 'svelte';
  import EmptyState from '$lib/components/ui/EmptyState.svelte';

  interface Props {
    title?: string;
    icon?: string;
    items: { id: string; icon?: string; title: string; subtitle?: string; href?: string; timestamp?: string }[];
    empty?: Snippet;
    class?: string;
  }
  const { title, icon, items, empty, class: klass = '' }: Props = $props();
</script>

<section class="rounded-2xl bg-surface-container-lowest p-md {klass}">
  {#if title}
    <h3 class="font-h4 text-h4 mb-sm text-on-surface">{title}</h3>
  {/if}
  {#if items.length}
    <ul class="flex flex-col divide-y divide-outline-variant/40">
      {#each items as i (i.id)}
        <li>
          <a
            href={i.href ?? '#'}
            class="flex items-center justify-between gap-sm py-sm hover:bg-surface-container-low"
          >
            <div class="min-w-0">
              <p class="font-label-md text-label-md truncate text-on-surface">{i.title}</p>
              {#if i.subtitle}
                <p class="truncate text-[12px] text-on-surface-variant">{i.subtitle}</p>
              {/if}
            </div>
            {#if i.timestamp}
              <span class="shrink-0 text-[12px] text-on-surface-variant">{i.timestamp}</span>
            {/if}
          </a>
        </li>
      {/each}
    </ul>
  {:else if empty}
    {@render empty()}
  {:else}
    <EmptyState icon={icon ?? 'inbox'} title="Keine Einträge" />
  {/if}
</section>

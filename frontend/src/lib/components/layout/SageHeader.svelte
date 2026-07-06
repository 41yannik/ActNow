<script lang="ts">
  // Salbei-Header (Sage band) aus der Vorlage (chrome.jsx: SageHeader + HeaderTopBar).
  // Wiederverwendbar für Discover, Favoriten, Community, Rewards.
  import type { Snippet } from 'svelte';
  import Icon from '../ui/Icon.svelte';

  interface Props {
    /** Big white headline (e.g. "Entdecke"). */
    title?: string;
    /** Sub-line under the title (e.g. greeting + city). */
    subtitle?: string;
    /** Show the centered ActNow logo chip in the top row. */
    showLogo?: boolean;
    /** Show the bell button (top-right) with an optional unread badge. */
    showBell?: boolean;
    unread?: number;
    onbell?: () => void;
    /** Trailing content next to the title (e.g. a "Kalender" chip). */
    titleTrailing?: Snippet;
    /** Content placed in the top-row right slot instead of the bell (e.g. points chip). */
    topRight?: Snippet;
    class?: string;
  }
  let {
    title,
    subtitle,
    showLogo = true,
    showBell = true,
    unread = 0,
    onbell,
    titleTrailing,
    topRight,
    class: klass = '',
  }: Props = $props();

  const hasTopRow = $derived(showLogo || showBell || !!topRight);
</script>

<div
  class="relative overflow-hidden bg-primary-container bg-sage-pattern rounded-b-header
         pb-2.5 text-white {klass}"
  style="padding-top: max(2.5rem, env(safe-area-inset-top));"
>
  {#if hasTopRow}
    <div class="flex h-[60px] items-center justify-between px-4">
      <!-- left spacer keeps the logo centered -->
      <div class="w-9 shrink-0"></div>

      {#if showLogo}
        <img
          src="/logo_actnow.png"
          alt="ActNow"
          class="h-[52px] w-[52px] rounded-full object-cover"
        />
      {:else}
        <div></div>
      {/if}

      <div class="flex w-9 shrink-0 items-center justify-end">
        {#if topRight}
          {@render topRight()}
        {:else if showBell}
          <button
            type="button"
            onclick={() => onbell?.()}
            class="relative flex h-9 w-9 items-center justify-center rounded-full border-none bg-white/20 text-white transition-colors hover:bg-white/30"
            aria-label="Benachrichtigungen"
          >
            <Icon name="notifications" size={18} class="text-white" />
            {#if unread > 0}
              <span
                class="absolute -right-0.5 -top-0.5 flex h-[18px] min-w-[18px] items-center justify-center
                       rounded-full border-2 border-primary-container bg-tertiary px-1
                       text-[10px] font-bold text-white"
              >
                {unread}
              </span>
            {/if}
          </button>
        {/if}
      </div>
    </div>
  {/if}

  {#if title || subtitle || titleTrailing}
    <div class="flex items-end justify-between gap-3 px-[22px] pb-4 pt-1">
      <div class="min-w-0">
        {#if title}
          <div class="font-bold tracking-tight text-white" style="font-size:28px;line-height:1.1;">
            {title}
          </div>
        {/if}
        {#if subtitle}
          <div class="mt-0.5 text-[13px] text-white/90">{subtitle}</div>
        {/if}
      </div>
      {#if titleTrailing}
        <div class="shrink-0">{@render titleTrailing()}</div>
      {/if}
    </div>
  {/if}
</div>

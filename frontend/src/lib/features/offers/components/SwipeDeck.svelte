<script lang="ts">
  /**
   * SwipeDeck — Tinder-style stack of offer cards.
   *
   * Behavior:
   *  • Pointer events cover mouse / touch / pen with one path.
   *  • During drag the active card translates + rotates; LIKE/NOPE overlays
   *    fade in proportionally (rendered inside SwipeCard).
   *  • On release, if |dx| > `swipeThreshold` the card flies off-screen
   *    and `on:swipe` is dispatched; otherwise it snaps back.
   *  • Programmatic API: bind:this and call `swipeLeft / swipeRight / undo`.
   *  • Keyboard: ArrowLeft / ArrowRight commit a swipe when deck is focused.
   *  • Honors `prefers-reduced-motion` (no rotation, fade instead of fly-off).
   */
  import type { Offer } from '$lib/types/domain';
  import type { SwipeDirection, SwipeEvent } from './swipe.types';
  import SwipeCard from './SwipeCard.svelte';

  interface Props {
    offers: Offer[];
    swipeThreshold?: number;
    rotationFactor?: number;
    bufferSize?: number;
    onswipe?: (e: SwipeEvent) => void;
    onempty?: () => void;
    /** Saved offer ids — toggles the favorite state on the top card. */
    savedIds?: Set<string>;
    /** Toggle save for an offer (favorite button on the top card). */
    ontogglesave?: (offerId: string) => void;
    /** Open the detail view for an offer (tap on the top card). */
    onopendetail?: (offerId: string) => void;
    class?: string;
  }
  let {
    offers,
    swipeThreshold = 100,
    rotationFactor = 0.05,
    bufferSize = 3,
    onswipe,
    onempty,
    savedIds,
    ontogglesave,
    onopendetail,
    class: klass = '',
  }: Props = $props();

  // ── Reactive state ─────────────────────────────────────────────────────────
  /** Queue of remaining offers; top = index 0. */
  let queue: Offer[] = $state([]);
  /** Undo stack of (offer, direction) for `undo()`. */
  let history: Array<{ offer: Offer; direction: SwipeDirection }> = $state([]);

  // Re-seed when parent passes a new list (e.g. after prefetch refill).
  $effect(() => {
    queue = [...offers];
  });

  let dragX = $state(0);
  let dragY = $state(0);
  let dragging = $state(false);
  let pointerId: number | null = null;
  let startX = 0;
  let startY = 0;
  let exiting = $state<null | { direction: SwipeDirection; offerId: string }>(null);
  let cardEl: HTMLDivElement | null = null;

  const prefersReducedMotion =
    typeof window !== 'undefined' && window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // ── Geometry helpers ──────────────────────────────────────────────────────
  const rotation = $derived(prefersReducedMotion ? 0 : dragX * rotationFactor);

  // Visible cards (top first). Depth cards are visual only.
  const visible = $derived(queue.slice(0, bufferSize));

  // ── Pointer drag ──────────────────────────────────────────────────────────
  function onPointerDown(e: PointerEvent) {
    if (!queue.length || exiting) return;
    pointerId = e.pointerId;
    dragging = true;
    startX = e.clientX;
    startY = e.clientY;
    (e.currentTarget as HTMLElement).setPointerCapture(e.pointerId);
  }
  function onPointerMove(e: PointerEvent) {
    if (!dragging || e.pointerId !== pointerId) return;
    dragX = e.clientX - startX;
    dragY = e.clientY - startY;
  }
  function onPointerUp(e: PointerEvent) {
    if (!dragging || e.pointerId !== pointerId) return;
    dragging = false;
    pointerId = null;
    if (Math.abs(dragX) > swipeThreshold) {
      commit(dragX > 0 ? 'right' : 'left');
    } else {
      // Snap back.
      dragX = 0;
      dragY = 0;
    }
  }

  // ── Commit / undo ─────────────────────────────────────────────────────────
  function commit(direction: SwipeDirection) {
    const top = queue[0];
    if (!top || exiting) return;
    exiting = { direction, offerId: top.id };

    const flyDistance = typeof window !== 'undefined' ? window.innerWidth * 1.2 : 800;
    if (prefersReducedMotion) {
      dragX = 0;
      dragY = 0;
    } else {
      dragX = direction === 'right' ? flyDistance : -flyDistance;
    }

    // Wait for transition, then pop the card.
    window.setTimeout(
      () => {
        history = [...history, { offer: top, direction }];
        queue = queue.slice(1);
        onswipe?.({ direction, offerId: top.id });
        exiting = null;
        dragX = 0;
        dragY = 0;
        if (queue.length === 0) onempty?.();
      },
      prefersReducedMotion ? 0 : 280,
    );
  }

  function undo() {
    const last = history[history.length - 1];
    if (!last) return;
    history = history.slice(0, -1);
    queue = [last.offer, ...queue];
  }

  // ── Imperative API ────────────────────────────────────────────────────────
  // Exposed via `bind:this`. Svelte 5: `export` from `<script module>` is for
  // module-level — for instance methods we attach via `$$` is not available, so
  // expose handlers through a tiny accessor pattern.
  export function swipeLeft() {
    commit('left');
  }
  export function swipeRight() {
    commit('right');
  }
  export function undoLast() {
    undo();
  }
  export function topOfferId(): string | null {
    return queue[0]?.id ?? null;
  }

  // ── Keyboard ──────────────────────────────────────────────────────────────
  function onKey(e: KeyboardEvent) {
    if (e.key === 'ArrowLeft') {
      e.preventDefault();
      commit('left');
    } else if (e.key === 'ArrowRight') {
      e.preventDefault();
      commit('right');
    }
  }

  // Active card transform.
  const transform = $derived(
    exiting || dragging
      ? `translate(${dragX}px, ${dragY}px) rotate(${rotation}deg)`
      : 'translate(0,0) rotate(0deg)',
  );
  const transition = $derived(dragging ? 'none' : 'transform 0.28s ease, opacity 0.28s ease');
  const opacity = $derived(exiting ? 0 : 1);
</script>

<!-- svelte-ignore a11y_no_noninteractive_tabindex, a11y_no_noninteractive_element_interactions -->
<div
  bind:this={cardEl}
  class="relative w-full max-w-md mx-auto h-[58vh] min-h-[420px] max-h-[560px] flex items-center justify-center select-none {klass}"
  role="application"
  tabindex="0"
  aria-roledescription="card stack"
  aria-label="Angebote zum Durchwischen"
  onkeydown={onKey}
>
  {#if visible.length === 0}
    <!-- Empty slot — parent should render an EmptyState above this component. -->
    <div class="text-on-surface-variant font-body-md">Keine weiteren Angebote.</div>
  {/if}

  {#each visible as offer, i (offer.id)}
    {#if i === 0}
      <!-- Active (top) card -->
      <div
        class="absolute w-full h-full z-30 touch-none cursor-grab active:cursor-grabbing"
        style="transform: {transform}; transition: {transition}; opacity: {opacity};"
        role="button"
        tabindex="-1"
        aria-label={`Wische rechts zum Bewerben oder links zum Verwerfen: ${offer.title}`}
        onpointerdown={onPointerDown}
        onpointermove={onPointerMove}
        onpointerup={onPointerUp}
        onpointercancel={onPointerUp}
      >
        <SwipeCard
          {offer}
          {dragX}
          threshold={swipeThreshold}
          saved={savedIds?.has(offer.id) ?? false}
          ontogglesave={() => ontogglesave?.(offer.id)}
          onopen={() => onopendetail?.(offer.id)}
          class="h-full"
        />
      </div>
    {:else}
      <!-- Depth cards (visual only) -->
      <div
        class="absolute w-full h-[96%] rounded-card bg-surface-container-high shadow"
        style="
          transform: scale({1 - i * 0.04}) translateY({i * 12}px);
          z-index: {30 - i};
          opacity: {1 - i * 0.15};
        "
        aria-hidden="true"
      ></div>
    {/if}
  {/each}
</div>

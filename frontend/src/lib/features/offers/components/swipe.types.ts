/**
 * Public types for the SwipeDeck feature.
 */
export type SwipeDirection = 'left' | 'right';

export interface SwipeEvent {
  direction: SwipeDirection;
  offerId: string;
}

/**
 * Imperative API exposed by `SwipeDeck`:
 *
 *   <SwipeDeck bind:this={deck} ... />
 *   deck.swipeLeft(); deck.swipeRight(); deck.undo();
 */
export interface SwipeDeckApi {
  swipeLeft: () => void;
  swipeRight: () => void;
  undo: () => void;
  /** Currently visible (top) offer id, if any. */
  topOfferId: () => string | null;
}

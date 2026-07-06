// TODO(backend): no schema support — design shell only.
// The prototype shows per-offer fields that the backend doesn't store yet:
// friends taking part, distance in km, an "SOS" flag and a calendar-fit hint.
// We derive them deterministically from the offer id so the UI is stable
// across reloads. Replace with real data once the backend supports it.

export type CalendarMatch = 'fits' | 'partial';

export interface OfferEnrichment {
  /** First names of friends "taking part". */
  friends: string[];
  /** Total helpers already taking part (for the "+N weitere" pills). */
  taken: number;
  /** Distance from the user in km. */
  km: number;
  /** Short-notice / urgent flag. */
  sos: boolean;
  /** Whether the offer fits the user's (mock) calendar. */
  match: CalendarMatch;
}

const FRIEND_POOL = ['Anna', 'Max', 'Lisa', 'Lena', 'Jonas', 'Mara'];

/** Tiny stable string hash → non-negative int. */
function hash(id: string): number {
  let h = 0;
  for (let i = 0; i < id.length; i++) {
    h = (h << 5) - h + id.charCodeAt(i);
    h |= 0;
  }
  return Math.abs(h);
}

export function enrichOffer(offerId: string): OfferEnrichment {
  const h = hash(offerId);
  const friendCount = h % 3; // 0, 1 or 2 friends
  const friends = FRIEND_POOL.slice((h >> 2) % 3, ((h >> 2) % 3) + friendCount);
  return {
    friends,
    taken: 4 + (h % 12),
    km: Number((1 + (h % 80) / 10).toFixed(1)),
    sos: h % 7 === 0,
    match: h % 4 === 0 ? 'partial' : 'fits',
  };
}

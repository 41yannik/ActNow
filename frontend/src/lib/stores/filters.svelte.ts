// Discover filter state, synced to URL.
import { goto } from '$app/navigation';
import { page } from '$app/state';
import type { OfferType } from '$lib/types/database';

export interface OfferFilters {
  location: string | null;
  available_from: string | null;
  available_to: string | null;
  offer_type: OfferType | null;
  tags: string[];
}

export function readFilters(searchParams: URLSearchParams): OfferFilters {
  return {
    location: searchParams.get('loc'),
    available_from: searchParams.get('from'),
    available_to: searchParams.get('to'),
    offer_type: (searchParams.get('type') as OfferType | null) ?? null,
    tags: searchParams.get('tags')?.split(',').filter(Boolean) ?? [],
  };
}

export function writeFilters(filters: Partial<OfferFilters>) {
  const url = new URL(page.url);
  const set = (k: string, v: string | null) => {
    if (v) url.searchParams.set(k, v);
    else url.searchParams.delete(k);
  };
  if ('location' in filters) set('loc', filters.location ?? null);
  if ('available_from' in filters) set('from', filters.available_from ?? null);
  if ('available_to' in filters) set('to', filters.available_to ?? null);
  if ('offer_type' in filters) set('type', filters.offer_type ?? null);
  if ('tags' in filters) set('tags', filters.tags?.length ? filters.tags.join(',') : null);
  void goto(url, { replaceState: true, keepFocus: true, noScroll: true });
}

export const EMPTY_FILTERS: OfferFilters = {
  location: null,
  available_from: null,
  available_to: null,
  offer_type: null,
  tags: [],
};

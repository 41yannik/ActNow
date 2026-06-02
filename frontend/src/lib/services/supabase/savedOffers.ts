// Saved offers (Favoriten) queries against the existing `saved_offers` table.
// Backend query layer only — no schema change.
import { supabase } from './client';
import type { SavedOfferRow, SavedOfferWithOffer, UUID } from '$lib/types/database';

/** List the offers a helper has saved (most recent first). */
export async function listSavedOffers(helperProfileId: UUID): Promise<SavedOfferWithOffer[]> {
  const { data, error } = await supabase
    .from('saved_offers')
    .select('id, helper_profile_id, offer_id, created_at, offer:offers(*)')
    .eq('helper_profile_id', helperProfileId)
    .order('created_at', { ascending: false });
  if (error) throw error;
  return (data ?? []) as unknown as SavedOfferWithOffer[];
}

/** Just the offer ids a helper has saved — handy for toggling bookmark state. */
export async function listSavedOfferIds(helperProfileId: UUID): Promise<Set<UUID>> {
  const { data, error } = await supabase
    .from('saved_offers')
    .select('offer_id')
    .eq('helper_profile_id', helperProfileId);
  if (error) throw error;
  return new Set((data ?? []).map((r) => (r as { offer_id: UUID }).offer_id));
}

/** Save an offer (idempotent thanks to the unique constraint). */
export async function saveOffer(
  helperProfileId: UUID,
  offerId: UUID
): Promise<SavedOfferRow> {
  const { data, error } = await supabase
    .from('saved_offers')
    .upsert(
      { helper_profile_id: helperProfileId, offer_id: offerId },
      { onConflict: 'helper_profile_id,offer_id' }
    )
    .select()
    .single();
  if (error) throw error;
  return data as SavedOfferRow;
}

/** Remove a saved offer. */
export async function unsaveOffer(helperProfileId: UUID, offerId: UUID): Promise<void> {
  const { error } = await supabase
    .from('saved_offers')
    .delete()
    .eq('helper_profile_id', helperProfileId)
    .eq('offer_id', offerId);
  if (error) throw error;
}

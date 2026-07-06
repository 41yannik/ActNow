// Offer queries + RPC wrappers.
import { supabase } from './client';
import type {
  OfferRow,
  OfferStatus,
  OfferType,
  SearchOfferResult,
  UUID,
} from '$lib/types/database';

export interface SearchOffersInput {
  location?: string | null;
  available_from?: string | null;
  available_to?: string | null;
  offer_type?: OfferType | null;
  tags?: string[] | null;
  limit?: number;
  offset?: number;
}

export async function searchOffers(input: SearchOffersInput = {}): Promise<SearchOfferResult[]> {
  const { data, error } = await supabase.rpc('search_offers', {
    p_location_name: input.location ?? null,
    p_available_from: input.available_from ?? null,
    p_available_to: input.available_to ?? null,
    p_offer_type: input.offer_type ?? null,
    p_tags: input.tags ?? null,
    p_limit: input.limit ?? 20,
    p_offset: input.offset ?? 0,
  });
  if (error) throw error;
  return (data ?? []) as SearchOfferResult[];
}

export async function getOffer(id: UUID): Promise<OfferRow | null> {
  const { data, error } = await supabase.from('offers').select('*').eq('id', id).maybeSingle();
  if (error) throw error;
  return data;
}

export async function getOfferWithOrg(id: UUID) {
  const { data, error } = await supabase
    .from('offers')
    .select(
      `
      *,
      organization:organization_profiles!inner(
        organization_type,
        is_verified,
        profile:profiles!inner(id, display_name, slug, avatar_url, average_rating, rating_count)
      )
    `,
    )
    .eq('id', id)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function listOrgOffers(
  organizationProfileId: UUID,
  status?: OfferStatus,
): Promise<OfferRow[]> {
  let q = supabase
    .from('offers')
    .select('*')
    .eq('organization_profile_id', organizationProfileId)
    .order('created_at', { ascending: false });
  if (status) q = q.eq('status', status);
  const { data, error } = await q;
  if (error) throw error;
  return data ?? [];
}

export interface CreateOfferInput {
  organization_profile_id: UUID;
  title: string;
  description: string;
  offer_type: OfferType;
  category?: string | null;
  skills_required?: string[];
  min_age?: number | null;
  max_helpers?: number | null;
  location_name?: string | null;
  street?: string | null;
  postal_code?: string | null;
  city?: string | null;
  is_remote?: boolean;
  starts_at?: string | null;
  ends_at?: string | null;
  application_deadline?: string | null;
  requires_documents?: boolean;
}

export async function createOffer(input: CreateOfferInput): Promise<OfferRow> {
  const { data, error } = await supabase.from('offers').insert(input).select().single();
  if (error) throw error;
  return data as OfferRow;
}

export async function updateOffer(id: UUID, patch: Partial<CreateOfferInput>): Promise<OfferRow> {
  const { data, error } = await supabase
    .from('offers')
    .update(patch)
    .eq('id', id)
    .select()
    .single();
  if (error) throw error;
  return data as OfferRow;
}

export async function publishOffer(id: UUID): Promise<OfferRow> {
  const { data, error } = await supabase.rpc('publish_offer', { p_offer_id: id });
  if (error) throw error;
  return data as OfferRow;
}

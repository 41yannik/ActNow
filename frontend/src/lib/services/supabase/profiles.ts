// Profile-related queries (own profile, public profile, helper/org details, documents).
import { supabase } from './client';
import type {
  HelperDocumentRow,
  HelperProfileRow,
  OrganizationProfileRow,
  ProfileRow,
  UUID
} from '$lib/types/database';

export async function getOwnProfile(userId: UUID): Promise<ProfileRow | null> {
  const { data, error } = await supabase
    .from('profiles')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export interface ProfileUpdateInput {
  display_name?: string;
  avatar_url?: string | null;
  bio?: string | null;
  city?: string | null;
  postal_code?: string | null;
  phone?: string | null;
  website_url?: string | null;
}

export async function updateOwnProfile(profileId: UUID, patch: ProfileUpdateInput) {
  const { data, error } = await supabase
    .from('profiles')
    .update(patch)
    .eq('id', profileId)
    .select()
    .single();
  if (error) throw error;
  return data as ProfileRow;
}

export async function getHelperProfile(profileId: UUID): Promise<HelperProfileRow | null> {
  const { data, error } = await supabase
    .from('helper_profiles')
    .select('*')
    .eq('profile_id', profileId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function updateHelperProfile(
  profileId: UUID,
  patch: Partial<Omit<HelperProfileRow, 'profile_id' | 'created_at' | 'updated_at'>>
) {
  const { data, error } = await supabase
    .from('helper_profiles')
    .update(patch)
    .eq('profile_id', profileId)
    .select()
    .single();
  if (error) throw error;
  return data as HelperProfileRow;
}

export async function getOrganizationProfile(
  profileId: UUID
): Promise<OrganizationProfileRow | null> {
  const { data, error } = await supabase
    .from('organization_profiles')
    .select('*')
    .eq('profile_id', profileId)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function updateOrganizationProfile(
  profileId: UUID,
  patch: Partial<
    Omit<
      OrganizationProfileRow,
      'profile_id' | 'created_at' | 'updated_at' | 'is_verified' | 'verified_at'
    >
  >
) {
  const { data, error } = await supabase
    .from('organization_profiles')
    .update(patch)
    .eq('profile_id', profileId)
    .select()
    .single();
  if (error) throw error;
  return data as OrganizationProfileRow;
}

export async function getPublicProfileBySlug(slug: string) {
  const { data, error } = await supabase
    .from('public_profiles_view')
    .select('*')
    .eq('slug', slug)
    .maybeSingle();
  if (error) throw error;
  return data;
}

// ---- documents -------------------------------------------------------------

export async function listHelperDocuments(helperProfileId: UUID): Promise<HelperDocumentRow[]> {
  const { data, error } = await supabase
    .from('helper_documents')
    .select('*')
    .eq('helper_profile_id', helperProfileId)
    .eq('status', 'active')
    .order('created_at', { ascending: false });
  if (error) throw error;
  return data ?? [];
}

export async function deleteHelperDocument(documentId: UUID) {
  const { error } = await supabase.from('helper_documents').delete().eq('id', documentId);
  if (error) throw error;
}

// Application queries + RPC wrappers.
import { supabase } from './client';
import type { ApplicationRow, ApplicationStatus, UUID } from '$lib/types/database';

export async function listApplicationsForOffer(
  offerId: UUID,
  status?: ApplicationStatus
): Promise<ApplicationRow[]> {
  let q = supabase
    .from('applications')
    .select('*, helper:helper_profiles!inner(profile:profiles!inner(*))')
    .eq('offer_id', offerId)
    .order('submitted_at', { ascending: false });
  if (status) q = q.eq('status', status);
  const { data, error } = await q;
  if (error) throw error;
  return (data ?? []) as ApplicationRow[];
}

export async function listApplicationsForHelper(
  helperProfileId: UUID,
  status?: ApplicationStatus | ApplicationStatus[]
) {
  let q = supabase
    .from('applications')
    .select('*, offer:offers!inner(*)')
    .eq('helper_profile_id', helperProfileId)
    .order('submitted_at', { ascending: false });
  if (Array.isArray(status)) q = q.in('status', status);
  else if (status) q = q.eq('status', status);
  const { data, error } = await q;
  if (error) throw error;
  return data ?? [];
}

export interface CreateApplicationInput {
  offer_id: UUID;
  helper_profile_id: UUID;
  motivation_text?: string | null;
  helper_message?: string | null;
}

export async function createApplication(input: CreateApplicationInput): Promise<ApplicationRow> {
  const { data, error } = await supabase.from('applications').insert(input).select().single();
  if (error) throw error;
  return data as ApplicationRow;
}

export async function acceptApplication(id: UUID): Promise<ApplicationRow> {
  const { data, error } = await supabase.rpc('accept_application', { p_application_id: id });
  if (error) throw error;
  return data as ApplicationRow;
}

export async function rejectApplication(id: UUID, reason?: string): Promise<ApplicationRow> {
  const { data, error } = await supabase.rpc('reject_application', {
    p_application_id: id,
    p_reason: reason ?? null
  });
  if (error) throw error;
  return data as ApplicationRow;
}

export async function withdrawApplication(id: UUID): Promise<ApplicationRow> {
  const { data, error } = await supabase.rpc('withdraw_application', { p_application_id: id });
  if (error) throw error;
  return data as ApplicationRow;
}

export async function completeApplication(id: UUID): Promise<ApplicationRow> {
  const { data, error } = await supabase.rpc('complete_application', { p_application_id: id });
  if (error) throw error;
  return data as ApplicationRow;
}

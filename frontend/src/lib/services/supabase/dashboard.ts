// Aggregations for the org dashboard.
import { supabase } from './client';
import type { UUID } from '$lib/types/database';

export interface OrgDashboardMetrics {
  open_offers: number;
  new_applications: number;
  upcoming_engagements: number;
  unread_messages: number;
}

export async function getOrgDashboardMetrics(
  organizationProfileId: UUID
): Promise<OrgDashboardMetrics> {
  // Run four count queries in parallel.
  const [openOffersQ, newAppsQ, upcomingQ, unreadQ] = await Promise.all([
    supabase
      .from('offers')
      .select('id', { count: 'exact', head: true })
      .eq('organization_profile_id', organizationProfileId)
      .in('status', ['published', 'paused']),
    supabase
      .from('applications')
      .select('id, offer:offers!inner(organization_profile_id)', { count: 'exact', head: true })
      .eq('offer.organization_profile_id', organizationProfileId)
      .eq('status', 'submitted'),
    supabase
      .from('applications')
      .select('id, offer:offers!inner(organization_profile_id, starts_at)', {
        count: 'exact',
        head: true
      })
      .eq('offer.organization_profile_id', organizationProfileId)
      .eq('status', 'accepted')
      .gte('offer.starts_at', new Date().toISOString()),
    supabase
      .from('messages')
      .select('id, conversation:conversations!inner(organization_profile_id)', {
        count: 'exact',
        head: true
      })
      .eq('conversation.organization_profile_id', organizationProfileId)
      .neq('status', 'read')
      .neq('sender_profile_id', organizationProfileId)
  ]);
  return {
    open_offers: openOffersQ.count ?? 0,
    new_applications: newAppsQ.count ?? 0,
    upcoming_engagements: upcomingQ.count ?? 0,
    unread_messages: unreadQ.count ?? 0
  };
}

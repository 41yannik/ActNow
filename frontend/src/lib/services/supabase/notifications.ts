// In-app notifications used by the Community activity feed.
import { supabase } from './client';
import { demoGuard, isDemoBlocked } from '$lib/config/demo';
import type { NotificationRow, UUID } from '$lib/types/database';

export async function listNotifications(limit = 30): Promise<NotificationRow[]> {
  const { data, error } = await supabase
    .from('notifications')
    .select('*')
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw error;
  return data ?? [];
}

export async function listApplicationNotifications(
  applicationIds: UUID[],
  limit = 100,
): Promise<NotificationRow[]> {
  if (applicationIds.length === 0) return [];
  const { data, error } = await supabase
    .from('notifications')
    .select('*')
    .eq('entity_type', 'application')
    .in('entity_id', applicationIds)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw error;
  return data ?? [];
}

export async function markNotificationRead(id: UUID): Promise<void> {
  if (isDemoBlocked()) return; // background read-tracking — silent no-op
  const { error } = await supabase
    .from('notifications')
    .update({ read_at: new Date().toISOString() })
    .eq('id', id)
    .is('read_at', null);
  if (error) throw error;
}

export async function markAllNotificationsRead(profileId: UUID): Promise<void> {
  demoGuard();
  const { error } = await supabase
    .from('notifications')
    .update({ read_at: new Date().toISOString() })
    .eq('recipient_profile_id', profileId)
    .is('read_at', null);
  if (error) throw error;
}

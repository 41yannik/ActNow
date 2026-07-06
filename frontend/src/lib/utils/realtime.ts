// Small wrapper around Supabase Realtime channels with typed payload helpers.
import type { RealtimeChannel, RealtimePostgresChangesPayload } from '@supabase/supabase-js';
import { supabase } from '$lib/services/supabase/client';

export interface ChangeFilter {
  schema?: string;
  table: string;
  /** PostgREST-style filter, e.g. "conversation_id=eq.<uuid>". */
  filter?: string;
}

export function subscribeChanges<T extends { [key: string]: unknown }>(
  channelName: string,
  filter: ChangeFilter,
  onChange: (payload: RealtimePostgresChangesPayload<T>) => void,
  event: 'INSERT' | 'UPDATE' | 'DELETE' | '*' = '*',
): RealtimeChannel {
  const channel = supabase.channel(channelName).on(
    // postgres_changes is a known string literal; cast keeps wrapper API simple.
    'postgres_changes' as never,
    {
      event,
      schema: filter.schema ?? 'public',
      table: filter.table,
      filter: filter.filter,
    } as never,
    (payload: unknown) => onChange(payload as RealtimePostgresChangesPayload<T>),
  );
  channel.subscribe();
  return channel;
}

export async function unsubscribe(channel: RealtimeChannel | null | undefined) {
  if (!channel) return;
  await supabase.removeChannel(channel);
}

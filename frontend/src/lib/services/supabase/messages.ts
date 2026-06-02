// Conversations + messages.
import { supabase } from './client';
import type {
  CommunityConversationRow,
  CommunitySummary,
  ConversationRow,
  MessageRow,
  UUID
} from '$lib/types/database';

export async function listConversationsForProfile(profileId: UUID) {
  // Profile may be either helper or organization; the conversations table has both ids.
  const { data, error } = await supabase
    .from('conversations')
    .select(
      `
      *,
      offer:offers!inner(id, title),
      helper:helper_profiles!inner(profile:profiles!inner(id, display_name, avatar_url)),
      organization:organization_profiles!inner(profile:profiles!inner(id, display_name, avatar_url)),
      last_message:messages(body, created_at, sender_profile_id)
    `
    )
    .or(`helper_profile_id.eq.${profileId},organization_profile_id.eq.${profileId}`)
    .order('last_message_at', { ascending: false, nullsFirst: false });
  if (error) throw error;
  return data ?? [];
}

export async function listCommunityConversations(
  limit = 50,
  offset = 0
): Promise<CommunityConversationRow[]> {
  const { data, error } = await supabase.rpc('list_community_conversations', {
    p_limit: limit,
    p_offset: offset
  });
  if (error) throw error;
  return (data ?? []) as CommunityConversationRow[];
}

export async function getCommunitySummary(): Promise<CommunitySummary> {
  const { data, error } = await supabase.rpc('get_community_summary');
  if (error) throw error;
  const row = Array.isArray(data) ? data[0] : data;
  return {
    unread_messages: row?.unread_messages ?? 0,
    unread_notifications: row?.unread_notifications ?? 0,
    total_unread: row?.total_unread ?? 0
  };
}

export async function markConversationRead(conversationId: UUID): Promise<number> {
  const { data, error } = await supabase.rpc('mark_conversation_read', {
    p_conversation_id: conversationId
  });
  if (error) throw error;
  return Number(data ?? 0);
}

export async function getConversation(id: UUID): Promise<ConversationRow | null> {
  const { data, error } = await supabase
    .from('conversations')
    .select('*')
    .eq('id', id)
    .maybeSingle();
  if (error) throw error;
  return data;
}

export async function listMessages(conversationId: UUID, limit = 100): Promise<MessageRow[]> {
  const { data, error } = await supabase
    .from('messages')
    .select('*')
    .eq('conversation_id', conversationId)
    .order('created_at', { ascending: true })
    .limit(limit);
  if (error) throw error;
  return data ?? [];
}

export async function sendMessage(
  conversationId: UUID,
  senderProfileId: UUID,
  body: string
): Promise<MessageRow> {
  const { data, error } = await supabase
    .from('messages')
    .insert({ conversation_id: conversationId, sender_profile_id: senderProfileId, body })
    .select()
    .single();
  if (error) throw error;
  return data as MessageRow;
}

export async function markMessageRead(messageId: UUID) {
  const { error } = await supabase
    .from('messages')
    .update({ status: 'read', read_at: new Date().toISOString() })
    .eq('id', messageId);
  if (error) throw error;
}

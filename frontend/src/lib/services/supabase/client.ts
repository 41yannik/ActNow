// Browser-side Supabase client.
// Server-side actions get their own client in src/lib/services/supabase/server.ts.
import { createClient, type SupabaseClient } from '@supabase/supabase-js';

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL ?? '';
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY ?? '';

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  // Non-fatal in dev so the showcase still renders. Real pages must check.
  console.warn(
    '[supabase] VITE_SUPABASE_URL or VITE_SUPABASE_ANON_KEY missing. ' +
      'Copy ../.env.example to frontend/.env to enable backend calls.',
  );
}

export const supabase: SupabaseClient = createClient(
  SUPABASE_URL || 'http://localhost:8000',
  SUPABASE_ANON_KEY || 'anon-key-missing',
  {
    auth: { persistSession: true, autoRefreshToken: true },
  },
);

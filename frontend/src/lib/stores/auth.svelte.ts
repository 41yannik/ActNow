// Auth store — holds Supabase session + current profile in a rune.
import { supabase } from '$lib/services/supabase/client';
import { getOwnProfile } from '$lib/services/supabase/profiles';
import type { ProfileRow } from '$lib/types/database';
import type { Session, User } from '@supabase/supabase-js';

interface AuthState {
  session: Session | null;
  user: User | null;
  profile: ProfileRow | null;
  loading: boolean;
}

const state = $state<AuthState>({
  session: null,
  user: null,
  profile: null,
  loading: true
});

let initialized = false;

export async function initAuth() {
  if (initialized) return;
  initialized = true;
  const { data } = await supabase.auth.getSession();
  await applySession(data.session);
  supabase.auth.onAuthStateChange((_event, session) => {
    void applySession(session);
  });
}

async function applySession(session: Session | null) {
  state.session = session;
  state.user = session?.user ?? null;
  if (session?.user) {
    try {
      state.profile = await getOwnProfile(session.user.id);
    } catch (err) {
      console.error('[auth] failed to load profile', err);
      state.profile = null;
    }
  } else {
    state.profile = null;
  }
  state.loading = false;
}

export const auth = {
  get session() {
    return state.session;
  },
  get user() {
    return state.user;
  },
  get profile() {
    return state.profile;
  },
  get loading() {
    return state.loading;
  },
  get isAuthenticated() {
    return !!state.session;
  },
  get role() {
    return state.profile?.role ?? null;
  },
  async refresh() {
    if (state.user) {
      try {
        state.profile = await getOwnProfile(state.user.id);
      } catch (err) {
        console.error('[auth] refresh failed', err);
      }
    }
  }
};

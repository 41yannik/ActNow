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
  loading: true,
});

let initialized = false;
const AUTH_INIT_TIMEOUT_MS = 3_000;
const PROFILE_TIMEOUT_MS = 5_000;

function withTimeout<T>(promise: Promise<T>, timeoutMs: number, label: string): Promise<T> {
  let timeoutId: ReturnType<typeof setTimeout> | undefined;
  const timeout = new Promise<never>((_, reject) => {
    timeoutId = setTimeout(() => {
      reject(new Error(`${label} timed out after ${timeoutMs}ms`));
    }, timeoutMs);
  });

  return Promise.race([promise, timeout]).finally(() => {
    if (timeoutId) clearTimeout(timeoutId);
  });
}

export async function initAuth() {
  if (initialized) return;
  initialized = true;
  supabase.auth.onAuthStateChange((_event, session) => {
    void applySession(session);
  });

  try {
    const { data } = await withTimeout(
      supabase.auth.getSession(),
      AUTH_INIT_TIMEOUT_MS,
      'Supabase auth session',
    );
    await applySession(data.session);
  } catch (err) {
    console.error('[auth] failed to initialize', err);
    await applySession(null);
  }
}

async function applySession(session: Session | null) {
  state.session = session;
  state.user = session?.user ?? null;
  if (session?.user) {
    try {
      state.profile = await withTimeout(
        getOwnProfile(session.user.id),
        PROFILE_TIMEOUT_MS,
        'Supabase profile lookup',
      );
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
  },
};

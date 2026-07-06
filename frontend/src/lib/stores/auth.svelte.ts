// Auth store — holds Supabase session + current profile in a rune.
import { supabase } from '$lib/services/supabase/client';
import { getOwnProfile } from '$lib/services/supabase/profiles';
import { DEMO_MODE, DEMO_ACCOUNTS, type DemoRole } from '$lib/config/demo';
import type { ProfileRow } from '$lib/types/database';
import type { Session, User } from '@supabase/supabase-js';

interface AuthState {
  session: Session | null;
  user: User | null;
  profile: ProfileRow | null;
  loading: boolean;
  demoError: boolean;
}

const state = $state<AuthState>({
  session: null,
  user: null,
  profile: null,
  loading: true,
  demoError: false,
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
    if (!data.session && DEMO_MODE) {
      await signInDemo('helper');
      return; // onAuthStateChange -> applySession takes over
    }
    await applySession(data.session);
  } catch (err) {
    console.error('[auth] failed to initialize', err);
    if (DEMO_MODE) state.demoError = true;
    await applySession(null);
  }
}

// Signs in with one of the fixed demo accounts (demo mode only).
async function signInDemo(role: DemoRole) {
  const account = DEMO_ACCOUNTS[role];
  const { error } = await supabase.auth.signInWithPassword({
    email: account.email,
    password: account.password,
  });
  if (error) {
    console.error('[auth] demo sign-in failed', error);
    state.demoError = true;
    await applySession(null);
  }
}

/**
 * Demo role switcher: swaps the session to the other demo account without a
 * prior signOut (supabase-js replaces the session atomically, so route guards
 * never see an unauthenticated state). Returns the target home route.
 */
export async function switchDemoRole(role: DemoRole): Promise<string | null> {
  if (!DEMO_MODE) return null;
  state.loading = true;
  await signInDemo(role);
  return state.demoError ? null : DEMO_ACCOUNTS[role].home;
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
  get demoError() {
    return state.demoError;
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

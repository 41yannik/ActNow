// Read-only demo mode (portfolio showcase deployment).
// Enabled at build time via VITE_DEMO_MODE=true; the demo backend is
// additionally set to read-only on the database level (see supabase/README.md).
export const DEMO_MODE = import.meta.env.VITE_DEMO_MODE === 'true';

export type DemoRole = 'helper' | 'org';

export const DEMO_ACCOUNTS: Record<
  DemoRole,
  { email: string; password: string; label: string; home: string }
> = {
  helper: {
    email: 'helper1@actnow.test',
    password: 'actnow-dev',
    label: 'Anna (Helferin)',
    home: '/discover',
  },
  org: {
    email: 'verein1@actnow.test',
    password: 'actnow-dev',
    label: 'SV Sonnenschein (Verein)',
    home: '/dashboard',
  },
};

export class DemoWriteBlockedError extends Error {
  constructor() {
    super('Im Demo-Modus sind Änderungen deaktiviert.');
    this.name = 'DemoWriteBlockedError';
  }
}

/**
 * Guard for interactive write actions: aborts the call with a user-facing
 * message. The existing catch blocks in the UI surface `err.message` as a
 * toast, so exactly one notification appears per blocked action.
 */
export function demoGuard(): void {
  if (!DEMO_MODE) return;
  throw new DemoWriteBlockedError();
}

/** Guard for automatic background writes: caller returns a substitute value. */
export function isDemoBlocked(): boolean {
  return DEMO_MODE;
}

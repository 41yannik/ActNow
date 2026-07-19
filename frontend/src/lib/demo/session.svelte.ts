import { DEMO_IDS, profiles } from './fixtures';
import type { ProfileRow } from '$lib/types/database';

export type DemoRole = 'helper' | 'org';

export const DEMO_ROLES: Record<DemoRole, { label: string; home: string; profileId: string }> = {
  helper: { label: 'Anna (Helferin)', home: '/discover', profileId: DEMO_IDS.helper },
  org: { label: 'SV Sonnenschein (Verein)', home: '/dashboard', profileId: DEMO_IDS.org },
};

let activeRole = $state<DemoRole>('helper');

function profileFor(role: DemoRole): ProfileRow {
  const profile = profiles.find((row) => row.id === DEMO_ROLES[role].profileId);
  if (!profile) throw new Error(`Demo-Profil für ${role} fehlt.`);
  return structuredClone(profile);
}

export const demoSession = {
  get activeRole() {
    return activeRole;
  },
  get profile() {
    return profileFor(activeRole);
  },
  get role() {
    return activeRole === 'org' ? 'organization' : 'helper';
  },
  get loading() {
    return false;
  },
  get isAuthenticated() {
    return true;
  },
  switchRole(role: DemoRole) {
    activeRole = role;
    return DEMO_ROLES[role].home;
  },
  ensureRole(role: DemoRole) {
    if (activeRole !== role) activeRole = role;
  },
  async refresh() {
    // Fixtures are immutable; kept as a no-op for profile component compatibility.
  },
};

// Temporary compatibility alias while the existing UI is migrated away from
// authentication terminology. This is a local display session, not a login.
export const auth = demoSession;

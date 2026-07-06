# ActNow — Supabase Backend

The ActNow backend lives entirely in Supabase. Since July 2026 the database is
**versioned as migrations**:

- [`migrations/`](./migrations) is the single source of truth for the database
  schema (tables, enums, triggers, RLS, RPCs, storage buckets & policies).
  Schema changes are made by **adding new migration files** — never by editing
  applied ones.
- [`seed.sql`](./seed.sql) contains development/staging seed data
  (referenced by `config.toml` → `[db.seed]`, applied automatically on
  `supabase db reset`). **Never apply the seed to production.**
- [`tests/rls_smoke.sql`](./tests/rls_smoke.sql) is the RLS smoke-test suite.
- [`../docs/schema.sql`](../docs/schema.sql) is the **frozen pre-migration
  reference** (deprecated — do not apply; see its header).

## Environments

| Environment | Project                                   | Notes |
| ----------- | ----------------------------------------- | ----- |
| Local       | Docker stack via `supabase start`         | Ports 54321–54329, Studio on 54323 |
| Staging     | `fhqgbenlufdqbihmmdrq` (eu-central-1)     | Free tier — auto-pauses after ~7 days idle; restore via dashboard or MCP `restore_project` |
| Production  | — (not yet created)                       | Create from the same migrations; **no seed**, custom SMTP + email confirmations required before launch |

Frontend env vars (`frontend/.env`): `VITE_SUPABASE_URL` + `VITE_SUPABASE_ANON_KEY`
(publishable `sb_publishable_...` key). See `frontend/.env.example`.

## Local development

```bash
./scripts/setup-backend.sh   # installs CLI if needed, starts stack, applies migrations + seed
# or manually:
supabase start
supabase db reset            # replays supabase/migrations/ + supabase/seed.sql
```

Seed accounts (dev/staging only, password `actnow-dev`):

| Email                 | Role         |
| --------------------- | ------------ |
| `admin@actnow.test`   | admin        |
| `helper1@actnow.test` | helper       |
| `helper2@actnow.test` | helper       |
| `helper3@actnow.test` | helper       |
| `verein1@actnow.test` | organization |
| `verein2@actnow.test` | organization |

> Note: cloud GoTrue rejects `.test` email domains for **new** signups — the
> seed accounts work because they are inserted directly. Use real-looking
> addresses when testing registration against staging.

## Deploying schema changes

Staging was initialized via the Supabase MCP (`apply_migration`), one call per
file in `migrations/`. File names carry the cloud-assigned versions — keep them
in sync (after applying, compare with `list_migrations`).

For future changes: add a new `migrations/<version>_<name>.sql`, apply it to
staging via MCP `apply_migration` (or `supabase link` + `supabase db push`),
then run `supabase db reset` locally to stay identical.

## Auth configuration (staging dashboard checklist)

These settings are **not** covered by migrations — set them under
Authentication in the dashboard of project `fhqgbenlufdqbihmmdrq`:

| Setting                    | Value                                    | Status |
| -------------------------- | ---------------------------------------- | ------ |
| Site URL                   | `http://localhost:5173`                  | ☐ todo |
| Additional Redirect URLs   | `http://localhost:5173/**`               | ☐ todo |
| Minimum password length    | `8` (frontend Zod already enforces 8)    | ☐ todo |
| Confirm email              | OFF for staging; **ON before production launch** (requires custom SMTP, e.g. Resend) | ✓ default |

The local `config.toml` mirrors these values for `supabase start`.

## Smoke-testing RLS

```bash
# local (needs seed data):
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_smoke.sql
# staging: run the file content via MCP execute_sql
```

The suite runs in a single transaction ending in ROLLBACK (no traces) and
covers: anon read/write boundaries, profile isolation, application visibility,
message participant scoping, protected-column escalation, and document-share
scoping. Success prints `RLS SMOKE TESTS PASSED`.

## Security-advisor triage (as of 2026-07-06)

Fixed via migrations `20260706125830` / `20260706125926`: Supabase's default
privileges had granted function EXECUTE to `anon` — revoked for all RPCs and
trigger/internal functions (RPCs remain `authenticated`-only by design).

Accepted / follow-ups:

- **`security_definer_view` (4 views, ERROR)** — intentional for now: the views
  expose only pre-filtered public data (active profiles, published offers) and
  `anon` deliberately lacks EXECUTE on `is_admin()`, which the underlying RLS
  policies call. Switching to `security_invoker` requires reworking anon
  policies first. Follow-up before production.
- **`function_search_path_mutable` (9 non-definer trigger functions, WARN)** —
  low risk (not `security definer`); add `set search_path` in a cleanup
  migration.
- **`extension_in_public` (citext, WARN)** — move to `extensions` schema in a
  cleanup migration.
- **`public_bucket_allows_listing` (avatars, offer-images, WARN)** — public
  buckets allow listing; tighten the SELECT policies once frontend storage
  usage lands.

## Signup contract

The `on_auth_user_created` trigger auto-creates a `profiles` row (plus matching
`helper_profiles` / `organization_profiles` row) on signup. The frontend must
send signup metadata:

```ts
await supabase.auth.signUp({
  email,
  password,
  options: {
    data: {
      role:         'helper' | 'organization', // 'admin' is rejected; admins are promoted via DB only
      display_name: 'Anna Helferin',
      slug:         'anna-helferin' // optional; auto-generated if omitted
    }
  }
});
```

## Promoting an admin

Admin role can only be granted by an existing admin (or directly in the DB):

```sql
update public.profiles set role = 'admin' where slug = 'some-trusted-user';
```

The `tg_profiles_protect_columns` trigger blocks any non-admin from changing
`role`, `status`, `slug`, `user_id`, `average_rating`, or `rating_count`.

## Storage buckets

| Bucket             | Public | Max size | Allowed MIME                                    | Path convention                                                |
| ------------------ | ------ | -------- | ----------------------------------------------- | -------------------------------------------------------------- |
| `avatars`          | yes    | 5 MB     | `image/jpeg`, `image/png`, `image/webp`         | `profiles/{profile_id}/...`                                    |
| `offer-images`     | yes    | 5 MB     | `image/jpeg`, `image/png`, `image/webp`         | `offers/{offer_id}/...`                                        |
| `helper-documents` | no     | 20 MB    | `application/pdf`, `image/jpeg`, `image/png`    | `helpers/{helper_profile_id}/documents/{document_id}.{ext}`   |

Access to `helper-documents` is enforced by RLS on `storage.objects` and is
allowed only for: the owning helper, admins, and organizations that have an
active row in `application_document_shares` pointing at the document via one
of their offers.

## RPC functions (called via `supabase.rpc(...)`)

| Function                                | Caller         | Purpose                                                              |
| --------------------------------------- | -------------- | -------------------------------------------------------------------- |
| `search_offers`                         | authenticated  | Feed/swipe query with filters; includes `has_applied` for caller     |
| `publish_offer`                         | owning org     | Transition draft/paused → published                                  |
| `accept_application`                    | owning org     | Atomic capacity check + status → accepted; auto-flips offer to filled |
| `reject_application`                    | owning org     | Status → rejected, stores optional reason in `organization_note`     |
| `withdraw_application`                  | applying helper| Status → withdrawn                                                   |
| `complete_application`                  | owning org     | Status → completed, unlocks rating creation                          |
| `create_conversation_for_application`   | participant    | Idempotent conversation lookup/insert for an application             |
| `list_community_conversations`          | authenticated  | Community inbox incl. unread counts                                  |
| `get_community_summary`                 | authenticated  | Unread message/notification totals                                   |
| `mark_conversation_read`                | participant    | Marks messages + related notifications read                          |

All RPCs are `security definer` with `set search_path`, EXECUTE granted to
`authenticated` only, and perform `auth.uid()` / `current_profile_id()`
ownership checks internally.

## Files

- [`migrations/`](./migrations) — schema as versioned migrations (source of truth)
- [`seed.sql`](./seed.sql) — dev/staging seed data
- [`tests/rls_smoke.sql`](./tests/rls_smoke.sql) — RLS smoke tests
- [`../docs/schema.sql`](../docs/schema.sql) — frozen pre-migration reference (deprecated)
- [`../docs/data-model.md`](../docs/data-model.md) — authoritative data-model spec
- [`../docs/api-contract.md`](../docs/api-contract.md) — frontend↔backend contract
- [`../.env.example`](../.env.example) — required environment variables

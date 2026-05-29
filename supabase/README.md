# ActNow — Supabase Backend

The ActNow backend lives entirely in Supabase. Per the repository convention
(`.github/copilot-instructions.md`) the database schema is **not** versioned as
migrations during early development. Instead:

- [`docs/schema.sql`](../docs/schema.sql) is the single source of truth for the
  database schema (tables, enums, triggers, RLS, RPCs, storage buckets &
  policies).
- [`docs/seed.sql`](../docs/seed.sql) contains development seed data.

This folder only contains operational glue (this README + optional local
config). No `supabase/migrations/` directory is created on purpose.

## Prerequisites

- [Supabase CLI](https://supabase.com/docs/guides/cli) (>= v1.150)
- Docker (for `supabase start`)
- `psql` (PostgreSQL client)

## 1. Start a local Supabase stack

```bash
supabase start
```

This boots Postgres, Auth, Storage, and Studio locally. Note the printed URLs
and keys — copy them into your `.env` (use `.env.example` as a template).

## 2. Apply the schema

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/schema.sql
```

The script is **replayable**: every `DROP … IF EXISTS` runs first, so you can
re-apply it any time. **Re-applying drops all app tables and their data.**

## 3. Load seed data

```bash
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/seed.sql
```

Seed accounts (dev only, password `actnow-dev`):

| Email                 | Role         |
| --------------------- | ------------ |
| `admin@actnow.test`   | admin        |
| `helper1@actnow.test` | helper       |
| `helper2@actnow.test` | helper       |
| `helper3@actnow.test` | helper       |
| `verein1@actnow.test` | organization |
| `verein2@actnow.test` | organization |

> The seed file disables a few business-logic triggers around the controlled
> inserts and re-enables them at the end. Aggregate columns (`profiles.average_rating`,
> `offers.accepted_helpers_count`) are recomputed before commit.

## 4. Reset the database

```bash
supabase db reset             # nukes the DB
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/schema.sql
psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/seed.sql
```

## Signup contract

`docs/schema.sql` installs an `on_auth_user_created` trigger that auto-creates
a `profiles` row (plus matching `helper_profiles` / `organization_profiles`
row) when a user signs up. The frontend must send signup metadata:

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

All RPCs are `security definer`, `revoke ... from public`, `grant ... to authenticated`,
and perform `auth.uid()` / `current_profile_id()` ownership checks internally.

## Smoke-testing RLS

After loading seed data, log in as one of the dev users from Supabase Studio,
copy the JWT, and try queries against PostgREST. Quick sanity checks:

- `helper1` cannot `select * from helper_documents` belonging to `helper3`.
- `verein1` **can** see `helper1`'s document (it has an active share via
  application 40000000-…-101).
- Any helper attempting `update profiles set role='admin'` is rejected.
- `insert into ratings ...` for an application whose status ≠ `completed` is
  rejected by the `ratings_insert_after_completion` policy.

## Files

- [`docs/schema.sql`](../docs/schema.sql) — schema, RLS, triggers, RPCs, storage
- [`docs/seed.sql`](../docs/seed.sql) — dev seed data
- [`docs/data-model.md`](../docs/data-model.md) — authoritative data-model spec
- [`docs/api-contract.md`](../docs/api-contract.md) — frontend↔backend contract
- [`.env.example`](../.env.example) — required environment variables

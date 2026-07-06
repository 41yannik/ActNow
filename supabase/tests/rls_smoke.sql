-- =============================================================================
-- ActNow RLS smoke tests
--
-- Verifies the core row-level-security guarantees against a seeded database
-- (requires the fixed UUIDs from supabase/seed.sql).
--
-- Run locally:   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f supabase/tests/rls_smoke.sql
-- Run on cloud:  execute the file content via the Supabase MCP execute_sql tool.
--
-- The whole script runs in one transaction and ends with ROLLBACK — it leaves
-- no traces. Each scenario switches role/JWT via set_config(..., true).
-- A failed assertion raises 'FAIL: ...' and aborts the script.
--
-- Scope note: this exercises the policy layer (set local role + jwt claims).
-- It does not test PostgREST/JWT verification itself — that is covered by the
-- frontend smoke test against the running stack.
--
-- Seed identities (auth user id -> profile id):
--   helper1 Anna   00000000-0000-0000-0000-000000000010 -> 10000000-0000-0000-0000-000000000010
--   helper2 Bernd  00000000-0000-0000-0000-000000000011 -> 10000000-0000-0000-0000-000000000011
--   helper3 Clara  00000000-0000-0000-0000-000000000012 -> 10000000-0000-0000-0000-000000000012
--   verein1 SV     00000000-0000-0000-0000-000000000020 -> 10000000-0000-0000-0000-000000000020
--   verein2 Bunte  00000000-0000-0000-0000-000000000021 -> 10000000-0000-0000-0000-000000000021
-- =============================================================================

begin;

-- ---- Scenario 1: anon --------------------------------------------------------
set local role anon;
select set_config('request.jwt.claims', '{"role":"anon"}', true);

do $$
declare n int;
begin
  -- 1a) anon can read published offers via the public view
  select count(*) into n from public.published_offers_view;
  if n < 1 then
    raise exception 'FAIL 1a: anon sees no published offers via published_offers_view';
  end if;

  -- 1b) anon cannot insert offers (any error counts as pass)
  begin
    insert into public.offers (organization_profile_id, title, description, offer_type, city)
    values ('10000000-0000-0000-0000-000000000020', 'Hack Offer', 'This insert must be rejected by RLS.', 'single_event', 'Berlin');
    raise exception 'FAIL 1b: anon could insert into offers';
  exception
    when raise_exception then raise;
    when others then null; -- expected: rejected
  end;
end $$;

reset role;

-- ---- Scenario 2: helper1 profile isolation ----------------------------------
set local role authenticated;
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000010","role":"authenticated"}', true);

do $$
declare n int;
begin
  -- 2a) helper1 can update own profile
  update public.profiles set bio = 'smoke-test' where id = '10000000-0000-0000-0000-000000000010';
  get diagnostics n = row_count;
  if n <> 1 then
    raise exception 'FAIL 2a: helper1 could not update own profile (rows=%)', n;
  end if;

  -- 2b) helper1 cannot update a foreign profile (policy filters row -> 0 rows)
  update public.profiles set bio = 'hacked' where id = '10000000-0000-0000-0000-000000000011';
  get diagnostics n = row_count;
  if n <> 0 then
    raise exception 'FAIL 2b: helper1 updated a foreign profile (rows=%)', n;
  end if;
end $$;

-- ---- Scenario 3: applications isolation --------------------------------------
do $$
declare n int;
begin
  -- helper1 sees own applications
  select count(*) into n from public.applications
    where helper_profile_id = '10000000-0000-0000-0000-000000000010';
  if n < 1 then
    raise exception 'FAIL 3a: helper1 sees none of their own applications';
  end if;

  -- helper2's application (40000000-...-0102) must be invisible to helper1
  select count(*) into n from public.applications
    where id = '40000000-0000-0000-0000-000000000102';
  if n <> 0 then
    raise exception 'FAIL 3b: helper1 can see helper2''s application';
  end if;
end $$;

-- ---- Scenario 4: messages only for participants ------------------------------
-- Conversation 60000000-...-0101 is helper1 <-> verein1. helper3 is uninvolved.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000012","role":"authenticated"}', true);

do $$
declare n int;
begin
  select count(*) into n from public.messages
    where conversation_id = '60000000-0000-0000-0000-000000000101';
  if n <> 0 then
    raise exception 'FAIL 4: helper3 can read messages of a foreign conversation (rows=%)', n;
  end if;
end $$;

-- ---- Scenario 5: protected profile columns -----------------------------------
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000010","role":"authenticated"}', true);

do $$
begin
  begin
    update public.profiles set role = 'admin' where id = '10000000-0000-0000-0000-000000000010';
    raise exception 'FAIL 5: helper1 could escalate own role to admin';
  exception
    when raise_exception then raise;
    when others then null; -- expected: blocked by tg_profiles_protect_columns
  end;
end $$;

-- ---- Scenario 6: document shares scoped to the right organization ------------
-- Doc 30000000-...-0012 (Clara) is shared via application 204 with verein2 only.
-- Doc 30000000-...-0010 (Anna)  is shared via application 101 with verein1 only.
select set_config('request.jwt.claims', '{"sub":"00000000-0000-0000-0000-000000000020","role":"authenticated"}', true);

do $$
declare n int;
begin
  -- verein1 sees Anna's shared document ...
  select count(*) into n from public.helper_documents
    where id = '30000000-0000-0000-0000-000000000010';
  if n <> 1 then
    raise exception 'FAIL 6a: verein1 cannot see the document shared with it (rows=%)', n;
  end if;

  -- ... but not Clara's document, which is shared with verein2
  select count(*) into n from public.helper_documents
    where id = '30000000-0000-0000-0000-000000000012';
  if n <> 0 then
    raise exception 'FAIL 6b: verein1 can see a document shared with another org (rows=%)', n;
  end if;
end $$;

reset role;

select 'RLS SMOKE TESTS PASSED' as result;

rollback;

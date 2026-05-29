-- =============================================================================
-- ActNow seed data (development / local Supabase)
-- Replayable: uses fixed UUIDs + `on conflict do nothing`/`do update`.
-- Apply AFTER docs/schema.sql:
--   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/seed.sql
-- =============================================================================
--
-- Seed accounts — DEV USE ONLY.
-- Passwords are set via a post-insert UPDATE using pgcrypto (see bottom of this file).
-- DO NOT use a hardcoded hash; bcrypt must be generated at apply-time.
--   admin@actnow.test      / actnow-dev
--   helper1@actnow.test    / actnow-dev
--   helper2@actnow.test    / actnow-dev
--   helper3@actnow.test    / actnow-dev
--   verein1@actnow.test    / actnow-dev
--   verein2@actnow.test    / actnow-dev
--
-- =============================================================================

begin;

-- Disable all triggers (incl. the auth → profile auto-create owned by
-- supabase_auth_admin) so we can insert with fixed UUIDs and deterministic
-- state. Re-enabled implicitly at end of session; we also reset explicitly.
set local session_replication_role = replica;

-- ---- auth.users -----------------------------------------------------------
-- Minimal columns; bcrypt hash of "actnow-dev".
-- Token columns must be '' not NULL — GoTrue's Scan fails on NULL strings.
insert into auth.users
  (instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
   raw_app_meta_data, raw_user_meta_data, created_at, updated_at, is_super_admin,
   confirmation_token, recovery_token, email_change_token_new, email_change,
   email_change_token_current, reauthentication_token)
values
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000001', 'authenticated', 'authenticated',
    'admin@actnow.test',   '$2a$10$abcdefghijklmnopqrstuuvbW7qiM7vKhMOjUaq0aA1zZJqA1zZJqA', now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), false, '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000010', 'authenticated', 'authenticated',
    'helper1@actnow.test', '$2a$10$abcdefghijklmnopqrstuuvbW7qiM7vKhMOjUaq0aA1zZJqA1zZJqA', now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), false, '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000011', 'authenticated', 'authenticated',
    'helper2@actnow.test', '$2a$10$abcdefghijklmnopqrstuuvbW7qiM7vKhMOjUaq0aA1zZJqA1zZJqA', now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), false, '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000012', 'authenticated', 'authenticated',
    'helper3@actnow.test', '$2a$10$abcdefghijklmnopqrstuuvbW7qiM7vKhMOjUaq0aA1zZJqA1zZJqA', now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), false, '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000020', 'authenticated', 'authenticated',
    'verein1@actnow.test', '$2a$10$abcdefghijklmnopqrstuuvbW7qiM7vKhMOjUaq0aA1zZJqA1zZJqA', now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), false, '', '', '', '', '', ''),
  ('00000000-0000-0000-0000-000000000000', '00000000-0000-0000-0000-000000000021', 'authenticated', 'authenticated',
    'verein2@actnow.test', '$2a$10$abcdefghijklmnopqrstuuvbW7qiM7vKhMOjUaq0aA1zZJqA1zZJqA', now(),
    '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(), false, '', '', '', '', '', '')
on conflict (id) do nothing;

-- ---- profiles -------------------------------------------------------------
insert into public.profiles
  (id, user_id, role, status, display_name, slug, bio, city, postal_code, country_code, average_rating, rating_count)
values
  ('10000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001',
    'admin',        'active', 'ActNow Admin',             'actnow-admin',
    'Plattform-Administration.', 'Berlin', '10115', 'DE', 0, 0),
  ('10000000-0000-0000-0000-000000000010', '00000000-0000-0000-0000-000000000010',
    'helper',       'active', 'Anna Helferin',            'anna-helferin',
    'Ich helfe gerne bei Sport- und Sozialeinsätzen.',           'Berlin',    '10115', 'DE', 0, 0),
  ('10000000-0000-0000-0000-000000000011', '00000000-0000-0000-0000-000000000011',
    'helper',       'active', 'Bernd Beispiel',           'bernd-beispiel',
    'Erfahrener Eventhelfer und Fahrer.',                        'Hamburg',   '20095', 'DE', 0, 0),
  ('10000000-0000-0000-0000-000000000012', '00000000-0000-0000-0000-000000000012',
    'helper',       'active', 'Clara Code',               'clara-code',
    'IT-affin, gerne digitale Aufgaben oder Übersetzungen.',     'München',   '80331', 'DE', 0, 0),
  ('10000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000020',
    'organization', 'active', 'SV Sonnenschein e.V.',     'sv-sonnenschein',
    'Sportverein für Jugend und Familie.',                       'Berlin',    '10115', 'DE', 0, 0),
  ('10000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000021',
    'organization', 'active', 'Initiative Bunte Stadt',   'initiative-bunte-stadt',
    'Initiative für Stadtteilarbeit und Integration.',           'Hamburg',   '20095', 'DE', 0, 0)
on conflict (id) do nothing;

-- ---- helper_profiles -------------------------------------------------------
insert into public.helper_profiles
  (profile_id, skills, languages, availability_note, has_drivers_license, has_car)
values
  ('10000000-0000-0000-0000-000000000010',
    array['event','social','first-aid'], array['de','en'], 'Wochenenden bevorzugt.', true,  true),
  ('10000000-0000-0000-0000-000000000011',
    array['driving','logistics','event'], array['de'],     'Abends und Wochenende.', true,  true),
  ('10000000-0000-0000-0000-000000000012',
    array['it','translation','remote'],   array['de','en','es'], 'Flexibel, remote.', false, false)
on conflict (profile_id) do nothing;

-- ---- organization_profiles -------------------------------------------------
insert into public.organization_profiles
  (profile_id, organization_type, legal_name, contact_person_name, contact_email, contact_phone, is_verified)
values
  ('10000000-0000-0000-0000-000000000020',
    'club',       'SV Sonnenschein e.V.',     'Maria Vorstand',  'kontakt@sv-sonnenschein.test', '+49 30 1234567', false),
  ('10000000-0000-0000-0000-000000000021',
    'initiative', 'Initiative Bunte Stadt',   'Tom Aktiv',       'hallo@bunte-stadt.test',       '+49 40 7654321', false)
on conflict (profile_id) do nothing;

-- ---- offers ----------------------------------------------------------------
insert into public.offers
  (id, organization_profile_id, title, description, offer_type, status, category, skills_required,
   max_helpers, city, postal_code, country_code, is_remote, starts_at, ends_at, application_deadline,
   published_at)
values
  -- 1. Single event, published, looking for helpers
  ('20000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000020',
    'Aufbau Sommerfest', 'Wir suchen Unterstützung beim Aufbau von Pavillons, Tischen und Bänken sowie bei der Essensausgabe.',
    'single_event', 'published', 'event', array['event','logistics'],
    8, 'Berlin', '10115', 'DE', false,
    now() + interval '14 days', now() + interval '14 days 8 hours', now() + interval '10 days',
    now() - interval '2 days'),

  -- 2. Recurring event, published
  ('20000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000020',
    'Wöchentliches Kindertraining', 'Unterstützung beim wöchentlichen Fußballtraining für Kinder.',
    'recurring_event', 'published', 'sport', array['sport','social'],
    3, 'Berlin', '10115', 'DE', false,
    now() + interval '7 days', now() + interval '7 days 2 hours', null,
    now() - interval '5 days'),

  -- 3. Flexible task, draft (only visible to owning org + admin)
  ('20000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000021',
    'Nachhilfe für Jugendliche', 'Flexible Nachhilfeangebote in Mathe, Deutsch oder Englisch nach Absprache.',
    'flexible_task', 'draft', 'education', array['teaching','social'],
    null, 'Hamburg', '20095', 'DE', false,
    null, null, null,
    null),

  -- 4. Digital/remote task, completed (used for ratings)
  ('20000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000021',
    'Übersetzung Webseite EN', 'Übersetzung der Vereinswebseite ins Englische, ca. 5 Seiten Text.',
    'digital_task', 'completed', 'it', array['translation','remote'],
    1, null, null, 'DE', true,
    now() - interval '30 days', now() - interval '20 days', now() - interval '32 days',
    now() - interval '40 days')
on conflict (id) do nothing;

-- ---- offer_recurrences -----------------------------------------------------
insert into public.offer_recurrences (id, offer_id, frequency, "interval", by_weekday, repeat_until)
values
  ('21000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000002',
    'weekly', 1, array[3], (current_date + interval '6 months')::date)
on conflict (id) do nothing;

-- ---- helper_documents ------------------------------------------------------
insert into public.helper_documents
  (id, helper_profile_id, document_type, status, title, description,
   storage_bucket, storage_path, mime_type, file_size_bytes, issued_at, expires_at)
values
  ('30000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000010',
    'criminal_record_certificate', 'active', 'Führungszeugnis',
    'Erweitertes Führungszeugnis, gültig bis nächstes Jahr.',
    'helper-documents',
    'helpers/10000000-0000-0000-0000-000000000010/documents/30000000-0000-0000-0000-000000000010.pdf',
    'application/pdf', 245678, current_date - interval '90 days', current_date + interval '275 days'),
  ('30000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000012',
    'qualification', 'active', 'Zertifikat Übersetzer EN',
    'IHK-Zertifikat Übersetzer Englisch.',
    'helper-documents',
    'helpers/10000000-0000-0000-0000-000000000012/documents/30000000-0000-0000-0000-000000000012.pdf',
    'application/pdf', 189000, current_date - interval '400 days', null)
on conflict (id) do nothing;

-- ---- applications ----------------------------------------------------------
insert into public.applications
  (id, offer_id, helper_profile_id, status, motivation_text, helper_message,
   submitted_at, accepted_at, completed_at)
values
  -- helper1 -> offer1 (submitted, pending)
  ('40000000-0000-0000-0000-000000000101', '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000010', 'submitted',
    'Ich bin am Wochenende verfügbar und packe gerne mit an.', 'Bis bald!',
    now() - interval '1 day', null, null),

  -- helper2 -> offer1 (accepted)
  ('40000000-0000-0000-0000-000000000102', '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000011', 'accepted',
    'Bringe Transporter mit für Material.', null,
    now() - interval '2 days', now() - interval '12 hours', null),

  -- helper3 -> offer4 (completed, ready for ratings)
  ('40000000-0000-0000-0000-000000000204', '20000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000012', 'completed',
    'Ich übernehme die Übersetzung gerne, habe Erfahrung damit.', 'Fertig!',
    now() - interval '35 days', now() - interval '34 days', now() - interval '20 days')
on conflict (id) do nothing;

-- ---- application_document_shares ------------------------------------------
insert into public.application_document_shares (id, application_id, document_id)
values
  ('50000000-0000-0000-0000-000000000101', '40000000-0000-0000-0000-000000000101',
    '30000000-0000-0000-0000-000000000010'),
  ('50000000-0000-0000-0000-000000000204', '40000000-0000-0000-0000-000000000204',
    '30000000-0000-0000-0000-000000000012')
on conflict (id) do nothing;

-- ---- conversations ---------------------------------------------------------
insert into public.conversations
  (id, application_id, offer_id, helper_profile_id, organization_profile_id, last_message_at)
values
  ('60000000-0000-0000-0000-000000000101', '40000000-0000-0000-0000-000000000101',
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000020',
    now() - interval '4 hours'),
  ('60000000-0000-0000-0000-000000000102', '40000000-0000-0000-0000-000000000102',
    '20000000-0000-0000-0000-000000000001',
    '10000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000020',
    now() - interval '6 hours'),
  ('60000000-0000-0000-0000-000000000204', '40000000-0000-0000-0000-000000000204',
    '20000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000021',
    now() - interval '20 days')
on conflict (id) do nothing;

-- ---- messages --------------------------------------------------------------
insert into public.messages
  (id, conversation_id, sender_profile_id, body, status, read_at, created_at)
values
  ('70000000-0000-0000-0000-000000000001', '60000000-0000-0000-0000-000000000101',
    '10000000-0000-0000-0000-000000000010',
    'Hallo, ich habe mich gerade beworben — gibt es noch offene Fragen?', 'read', now() - interval '5 hours',
    now() - interval '5 hours'),
  ('70000000-0000-0000-0000-000000000002', '60000000-0000-0000-0000-000000000101',
    '10000000-0000-0000-0000-000000000020',
    'Hi Anna, danke für die Bewerbung! Wir melden uns spätestens morgen.', 'sent', null,
    now() - interval '4 hours'),
  ('70000000-0000-0000-0000-000000000003', '60000000-0000-0000-0000-000000000102',
    '10000000-0000-0000-0000-000000000020',
    'Hallo Bernd, der Transporter wäre super — bitte um 7 Uhr da sein.', 'sent', null,
    now() - interval '6 hours')
on conflict (id) do nothing;

-- ---- ratings (only on completed application 204) --------------------------
insert into public.ratings
  (id, application_id, offer_id, rater_profile_id, rated_profile_id, score, comment)
values
  -- Helper rates org
  ('80000000-0000-0000-0000-000000000001', '40000000-0000-0000-0000-000000000204',
    '20000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000021',
    5, 'Klare Briefings, super Zusammenarbeit.'),
  -- Org rates helper
  ('80000000-0000-0000-0000-000000000002', '40000000-0000-0000-0000-000000000204',
    '20000000-0000-0000-0000-000000000004',
    '10000000-0000-0000-0000-000000000021', '10000000-0000-0000-0000-000000000012',
    5, 'Pünktlich, sorgfältig, sehr empfehlenswert!')
on conflict (id) do nothing;

-- ---- saved_offers ---------------------------------------------------------
insert into public.saved_offers (id, helper_profile_id, offer_id)
values
  ('90000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000010', '20000000-0000-0000-0000-000000000002')
on conflict (id) do nothing;

-- ---- notifications --------------------------------------------------------
insert into public.notifications (id, recipient_profile_id, type, title, body, entity_type, entity_id)
values
  ('a0000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000020',
    'application.submitted', 'Neue Bewerbung', 'Anna Helferin hat sich auf "Aufbau Sommerfest" beworben.',
    'application', '40000000-0000-0000-0000-000000000101'),
  ('a0000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000011',
    'application.accepted',  'Bewerbung angenommen', 'Deine Bewerbung für "Aufbau Sommerfest" wurde angenommen.',
    'application', '40000000-0000-0000-0000-000000000102')
on conflict (id) do nothing;

-- ---- System-managed aggregates (while triggers are still disabled) -------
-- These UPDATEs would otherwise trip `tg_profiles_protect_columns`.
select public.recompute_profile_rating(p.id)
  from public.profiles p
  where exists (select 1 from public.ratings r where r.rated_profile_id = p.id);

select public.recompute_offer_accepted_count(id) from public.offers;

-- ---- Re-enable triggers (explicit reset; `set local` would also unwind) --
set local session_replication_role = origin;

-- ---- Set real bcrypt passwords for seed accounts --------------------------
-- Must run AFTER session_replication_role is reset (triggers back on).
-- pgcrypto gen_salt produces a fresh salt each apply, so hashes differ each run.
UPDATE auth.users
SET encrypted_password = crypt('actnow-dev', gen_salt('bf', 10))
WHERE email LIKE '%@actnow.test';

commit;

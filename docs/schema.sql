-- =============================================================================
-- ActNow database schema
-- Single source of truth (per repo `.github/copilot-instructions.md`)
-- Authoritative spec: `docs/data-model.md`
-- =============================================================================
--
-- Reconciliation decisions vs `docs/api-contract.md` (api-contract to be updated):
--   1. Documents model: `helper_documents` + `application_document_shares`
--      (NOT a single `documents` table with `visibility`)
--   2. offer_type enum:    single_event | recurring_event | flexible_task | digital_task
--   3. offer_status enum:  draft | published | paused | filled | completed | cancelled | archived
--   4. application_status: submitted | shortlisted | accepted | rejected
--                          | withdrawn | cancelled | completed | no_show
--   5. Profile location:   city + postal_code + country_code (not single location_name)
--   6. Conversation is auto-created on `applications` INSERT
--   7. `avatars` storage bucket is public-read; `helper-documents` is strictly private
--   8. `organization_memberships` is deferred (one auth user = one org profile in MVP)
--
-- This file is REPLAYABLE: every drop is IF EXISTS, recreated in order.
-- Apply with:   psql "$SUPABASE_DB_URL" -v ON_ERROR_STOP=1 -f docs/schema.sql
-- =============================================================================

set client_min_messages = warning;

begin;

-- =============================================================================
-- 0. RESET (drop in reverse FK / dependency order)
-- =============================================================================

-- Storage policies (recreated below)
drop policy if exists "avatars_read_public"                  on storage.objects;
drop policy if exists "avatars_insert_own"                   on storage.objects;
drop policy if exists "avatars_update_own"                   on storage.objects;
drop policy if exists "avatars_delete_own"                   on storage.objects;
drop policy if exists "offer_images_read_public"             on storage.objects;
drop policy if exists "offer_images_write_owning_org"        on storage.objects;
drop policy if exists "helper_documents_select_owner"        on storage.objects;
drop policy if exists "helper_documents_select_shared_org"   on storage.objects;
drop policy if exists "helper_documents_select_admin"        on storage.objects;
drop policy if exists "helper_documents_write_owner"         on storage.objects;
drop policy if exists "helper_documents_delete_owner"        on storage.objects;

-- Auth trigger
drop trigger if exists on_auth_user_created on auth.users;

-- App tables (cascade drops constraints, indexes, policies, triggers)
drop table if exists public.reports                       cascade;
drop table if exists public.admin_audit_log               cascade;
drop table if exists public.notifications                 cascade;
drop table if exists public.saved_offers                  cascade;
drop table if exists public.ratings                       cascade;
drop table if exists public.messages                      cascade;
drop table if exists public.conversations                 cascade;
drop table if exists public.application_document_shares   cascade;
drop table if exists public.helper_documents              cascade;
drop table if exists public.applications                  cascade;
drop table if exists public.offer_recurrences             cascade;
drop table if exists public.offers                        cascade;
drop table if exists public.organization_profiles         cascade;
drop table if exists public.helper_profiles               cascade;
drop table if exists public.profiles                      cascade;

-- Views
drop view if exists public.public_profiles_view              cascade;
drop view if exists public.published_offers_view             cascade;
drop view if exists public.organization_rating_summary_view  cascade;
drop view if exists public.helper_rating_summary_view        cascade;

-- Functions
drop function if exists public.handle_new_auth_user()                     cascade;
drop function if exists public.is_admin()                                 cascade;
drop function if exists public.current_profile_id()                       cascade;
drop function if exists public.set_updated_at()                           cascade;
drop function if exists public.recompute_profile_rating(uuid)             cascade;
drop function if exists public.tg_ratings_recompute()                     cascade;
drop function if exists public.recompute_offer_accepted_count(uuid)       cascade;
drop function if exists public.tg_applications_status_side_effects()      cascade;
drop function if exists public.tg_applications_validate_status_change()   cascade;
drop function if exists public.tg_offers_validate_status_change()         cascade;
drop function if exists public.tg_profiles_protect_columns()              cascade;
drop function if exists public.tg_validate_document_share()               cascade;
drop function if exists public.tg_ensure_conversation_for_application()   cascade;
drop function if exists public.tg_validate_conversation_consistency()     cascade;
drop function if exists public.tg_messages_guard_update()                 cascade;
drop function if exists public.tg_messages_after_insert_side_effects()    cascade;
drop function if exists public.search_offers(text, timestamptz, timestamptz, offer_type, text[], int, int) cascade;
drop function if exists public.accept_application(uuid)                   cascade;
drop function if exists public.reject_application(uuid, text)             cascade;
drop function if exists public.withdraw_application(uuid)                 cascade;
drop function if exists public.complete_application(uuid)                 cascade;
drop function if exists public.publish_offer(uuid)                        cascade;
drop function if exists public.create_conversation_for_application(uuid)  cascade;
drop function if exists public.list_community_conversations(int, int)     cascade;
drop function if exists public.get_community_summary()                    cascade;
drop function if exists public.mark_conversation_read(uuid)               cascade;

-- Enum types
drop type if exists public.recurrence_frequency cascade;
drop type if exists public.message_status       cascade;
drop type if exists public.document_status      cascade;
drop type if exists public.document_type        cascade;
drop type if exists public.application_status   cascade;
drop type if exists public.offer_status         cascade;
drop type if exists public.offer_type           cascade;
drop type if exists public.organization_type    cascade;
drop type if exists public.profile_status       cascade;
drop type if exists public.user_role            cascade;

-- =============================================================================
-- 1. EXTENSIONS
-- =============================================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";
create extension if not exists "citext";

-- =============================================================================
-- 2. ENUM TYPES
-- =============================================================================

create type public.user_role            as enum ('helper', 'organization', 'admin');
create type public.profile_status       as enum ('active', 'inactive', 'suspended', 'deleted');
create type public.organization_type    as enum ('club', 'nonprofit', 'initiative', 'public_institution', 'company', 'private_person', 'other');
create type public.offer_type           as enum ('single_event', 'recurring_event', 'flexible_task', 'digital_task');
create type public.offer_status         as enum ('draft', 'published', 'paused', 'filled', 'completed', 'cancelled', 'archived');
create type public.application_status   as enum ('submitted', 'shortlisted', 'accepted', 'rejected', 'withdrawn', 'cancelled', 'completed', 'no_show');
create type public.document_type        as enum ('criminal_record_certificate', 'identity_document', 'qualification', 'certificate', 'other');
create type public.document_status      as enum ('active', 'expired', 'revoked', 'deleted');
create type public.message_status       as enum ('sent', 'read', 'deleted');
create type public.recurrence_frequency as enum ('daily', 'weekly', 'monthly', 'custom');

-- =============================================================================
-- 3. GENERIC TRIGGER FUNCTION
-- =============================================================================

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- Note: `public.current_profile_id()` and `public.is_admin()` reference
-- `public.profiles` and are created in §5 (after the table exists).

-- =============================================================================
-- 4. TABLES
-- =============================================================================

-- ---- 4.1 profiles ----------------------------------------------------------
create table public.profiles (
  id              uuid          primary key default gen_random_uuid(),
  user_id         uuid          not null references auth.users(id) on delete cascade,
  role            user_role     not null,
  status          profile_status not null default 'active',
  display_name    text          not null,
  slug            text          not null,
  avatar_url      text,
  bio             text,
  city            text,
  postal_code     text,
  country_code    char(2)       not null default 'DE',
  phone           text,
  website_url     text,
  average_rating  numeric(3,2)  not null default 0,
  rating_count    integer       not null default 0,
  created_at      timestamptz   not null default now(),
  updated_at      timestamptz   not null default now(),

  constraint profiles_user_id_unique         unique (user_id),
  constraint profiles_slug_unique            unique (slug),
  constraint profiles_display_name_length    check (char_length(display_name) between 2 and 120),
  constraint profiles_bio_length             check (bio is null or char_length(bio) <= 2000),
  constraint profiles_rating_range           check (average_rating >= 0 and average_rating <= 5),
  constraint profiles_rating_count_nonneg    check (rating_count >= 0),
  constraint profiles_slug_format            check (slug ~ '^[a-z0-9][a-z0-9-]{1,62}[a-z0-9]$')
);

create index profiles_role_idx   on public.profiles(role);
create index profiles_status_idx on public.profiles(status);
create index profiles_city_idx   on public.profiles(city);

create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function public.set_updated_at();

-- ---- 4.2 helper_profiles ---------------------------------------------------
create table public.helper_profiles (
  profile_id              uuid       primary key references public.profiles(id) on delete cascade,
  date_of_birth           date,
  skills                  text[]     not null default '{}',
  languages               text[]     not null default '{}',
  availability_note       text,
  has_drivers_license     boolean    not null default false,
  has_car                 boolean    not null default false,
  emergency_contact_name  text,
  emergency_contact_phone text,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  constraint helper_profiles_availability_note_length
    check (availability_note is null or char_length(availability_note) <= 1000)
);

create index helper_profiles_skills_gin_idx    on public.helper_profiles using gin(skills);
create index helper_profiles_languages_gin_idx on public.helper_profiles using gin(languages);

create trigger helper_profiles_set_updated_at
  before update on public.helper_profiles
  for each row execute function public.set_updated_at();

-- ---- 4.3 organization_profiles --------------------------------------------
create table public.organization_profiles (
  profile_id           uuid              primary key references public.profiles(id) on delete cascade,
  organization_type    organization_type not null default 'club',
  legal_name           text,
  registration_number  text,
  tax_id               text,
  contact_person_name  text,
  contact_email        citext,
  contact_phone        text,
  is_verified          boolean           not null default false,
  verified_at          timestamptz,
  created_at           timestamptz       not null default now(),
  updated_at           timestamptz       not null default now(),

  constraint organization_verified_consistency check (
    (is_verified = false and verified_at is null) or
    (is_verified = true  and verified_at is not null)
  )
);

create index organization_profiles_type_idx on public.organization_profiles(organization_type);

create trigger organization_profiles_set_updated_at
  before update on public.organization_profiles
  for each row execute function public.set_updated_at();

-- ---- 4.4 offers ------------------------------------------------------------
create table public.offers (
  id                       uuid          primary key default gen_random_uuid(),
  organization_profile_id  uuid          not null references public.organization_profiles(profile_id) on delete cascade,
  title                    text          not null,
  description              text          not null,
  offer_type               offer_type    not null,
  status                   offer_status  not null default 'draft',
  category                 text,
  skills_required          text[]        not null default '{}',
  min_age                  integer,
  max_helpers              integer,
  accepted_helpers_count   integer       not null default 0,
  location_name            text,
  street                   text,
  postal_code              text,
  city                     text,
  country_code             char(2)       not null default 'DE',
  is_remote                boolean       not null default false,
  starts_at                timestamptz,
  ends_at                  timestamptz,
  application_deadline     timestamptz,
  is_binding               boolean       not null default true,
  requires_documents       boolean       not null default false,
  published_at             timestamptz,
  completed_at             timestamptz,
  cancelled_at             timestamptz,
  created_at               timestamptz   not null default now(),
  updated_at               timestamptz   not null default now(),

  constraint offers_title_length            check (char_length(title) between 5 and 160),
  constraint offers_description_length      check (char_length(description) between 20 and 5000),
  constraint offers_min_age_range           check (min_age is null or min_age between 0 and 120),
  constraint offers_max_helpers_positive    check (max_helpers is null or max_helpers > 0),
  constraint offers_accepted_helpers_nonneg check (accepted_helpers_count >= 0),
  constraint offers_accepted_not_above_max  check (max_helpers is null or accepted_helpers_count <= max_helpers),
  constraint offers_time_order              check (starts_at is null or ends_at is null or ends_at > starts_at),
  constraint offers_deadline_before_start   check (application_deadline is null or starts_at is null or application_deadline <= starts_at),
  constraint offers_remote_location_check   check (is_remote = true or city is not null),
  constraint offers_published_consistency   check (
    (status = 'published' and published_at is not null) or status <> 'published'
  )
);

create index offers_organization_idx        on public.offers(organization_profile_id);
create index offers_status_idx              on public.offers(status);
create index offers_offer_type_idx          on public.offers(offer_type);
create index offers_city_idx                on public.offers(city);
create index offers_starts_at_idx           on public.offers(starts_at);
create index offers_published_at_idx        on public.offers(published_at desc);
create index offers_skills_required_gin_idx on public.offers using gin(skills_required);

create trigger offers_set_updated_at
  before update on public.offers
  for each row execute function public.set_updated_at();

-- ---- 4.5 offer_recurrences -------------------------------------------------
create table public.offer_recurrences (
  id           uuid                 primary key default gen_random_uuid(),
  offer_id     uuid                 not null references public.offers(id) on delete cascade,
  frequency    recurrence_frequency not null,
  "interval"   integer              not null default 1,
  by_weekday   integer[],
  repeat_until date,
  rrule        text,
  created_at   timestamptz          not null default now(),

  constraint offer_recurrences_offer_unique   unique (offer_id),
  constraint offer_recurrences_interval_pos   check ("interval" > 0),
  constraint offer_recurrences_weekday_range  check (by_weekday is null or by_weekday <@ array[1,2,3,4,5,6,7])
);

-- ---- 4.6 applications ------------------------------------------------------
create table public.applications (
  id                  uuid               primary key default gen_random_uuid(),
  offer_id            uuid               not null references public.offers(id) on delete cascade,
  helper_profile_id   uuid               not null references public.helper_profiles(profile_id) on delete cascade,
  status              application_status not null default 'submitted',
  motivation_text     text,
  organization_note   text,
  helper_message      text,
  submitted_at        timestamptz        not null default now(),
  accepted_at         timestamptz,
  rejected_at         timestamptz,
  withdrawn_at        timestamptz,
  completed_at        timestamptz,
  created_at          timestamptz        not null default now(),
  updated_at          timestamptz        not null default now(),

  constraint applications_unique_helper_offer  unique (offer_id, helper_profile_id),
  constraint applications_motivation_length    check (motivation_text   is null or char_length(motivation_text)   <= 2000),
  constraint applications_helper_message_len   check (helper_message    is null or char_length(helper_message)    <= 1000),
  constraint applications_org_note_length      check (organization_note is null or char_length(organization_note) <= 2000),
  constraint applications_status_timestamp_consistency check (
    (status = 'accepted'  and accepted_at  is not null) or
    (status = 'rejected'  and rejected_at  is not null) or
    (status = 'withdrawn' and withdrawn_at is not null) or
    (status = 'completed' and completed_at is not null) or
    status in ('submitted', 'shortlisted', 'cancelled', 'no_show')
  )
);

create index applications_offer_idx         on public.applications(offer_id);
create index applications_helper_idx        on public.applications(helper_profile_id);
create index applications_status_idx        on public.applications(status);
create index applications_submitted_at_idx  on public.applications(submitted_at desc);

create trigger applications_set_updated_at
  before update on public.applications
  for each row execute function public.set_updated_at();

-- ---- 4.7 helper_documents --------------------------------------------------
create table public.helper_documents (
  id                 uuid            primary key default gen_random_uuid(),
  helper_profile_id  uuid            not null references public.helper_profiles(profile_id) on delete cascade,
  document_type      document_type   not null,
  status             document_status not null default 'active',
  title              text            not null,
  description        text,
  storage_bucket     text            not null,
  storage_path       text            not null,
  mime_type          text            not null,
  file_size_bytes    bigint          not null,
  issued_at          date,
  expires_at         date,
  created_at         timestamptz     not null default now(),
  updated_at         timestamptz     not null default now(),

  constraint helper_documents_title_length         check (char_length(title) between 2 and 160),
  constraint helper_documents_file_size_positive   check (file_size_bytes > 0),
  constraint helper_documents_file_size_max        check (file_size_bytes <= 20971520), -- 20 MB
  constraint helper_documents_expiry_after_issue   check (issued_at is null or expires_at is null or expires_at >= issued_at),
  constraint helper_documents_storage_unique       unique (storage_bucket, storage_path)
);

create index helper_documents_helper_idx on public.helper_documents(helper_profile_id);
create index helper_documents_type_idx   on public.helper_documents(document_type);
create index helper_documents_status_idx on public.helper_documents(status);

create trigger helper_documents_set_updated_at
  before update on public.helper_documents
  for each row execute function public.set_updated_at();

-- ---- 4.8 application_document_shares ---------------------------------------
create table public.application_document_shares (
  id              uuid        primary key default gen_random_uuid(),
  application_id  uuid        not null references public.applications(id)    on delete cascade,
  document_id     uuid        not null references public.helper_documents(id) on delete cascade,
  shared_at       timestamptz not null default now(),
  revoked_at      timestamptz,
  created_at      timestamptz not null default now(),

  constraint application_document_shares_unique  unique (application_id, document_id),
  constraint application_document_shares_revoke_after_share
    check (revoked_at is null or revoked_at >= shared_at)
);

create index application_document_shares_app_idx on public.application_document_shares(application_id);
create index application_document_shares_doc_idx on public.application_document_shares(document_id);

-- ---- 4.9 conversations -----------------------------------------------------
create table public.conversations (
  id                       uuid        primary key default gen_random_uuid(),
  application_id           uuid        not null references public.applications(id)              on delete cascade,
  offer_id                 uuid        not null references public.offers(id)                    on delete cascade,
  helper_profile_id        uuid        not null references public.helper_profiles(profile_id)   on delete cascade,
  organization_profile_id  uuid        not null references public.organization_profiles(profile_id) on delete cascade,
  last_message_at          timestamptz,
  created_at               timestamptz not null default now(),
  updated_at               timestamptz not null default now(),

  constraint conversations_application_unique unique (application_id)
);

create index conversations_helper_idx on public.conversations(helper_profile_id);
create index conversations_org_idx    on public.conversations(organization_profile_id);

create trigger conversations_set_updated_at
  before update on public.conversations
  for each row execute function public.set_updated_at();

-- ---- 4.10 messages ---------------------------------------------------------
create table public.messages (
  id                 uuid           primary key default gen_random_uuid(),
  conversation_id    uuid           not null references public.conversations(id) on delete cascade,
  sender_profile_id  uuid           not null references public.profiles(id)      on delete cascade,
  body               text           not null,
  status             message_status not null default 'sent',
  read_at            timestamptz,
  created_at         timestamptz    not null default now(),
  updated_at         timestamptz    not null default now(),

  constraint messages_body_length     check (char_length(body) between 1 and 5000),
  constraint messages_read_consistency check (
    (status = 'read' and read_at is not null) or status <> 'read'
  )
);

create index messages_conversation_created_idx on public.messages(conversation_id, created_at asc);
create index messages_sender_idx                on public.messages(sender_profile_id);
create index messages_unread_conversation_sender_idx
  on public.messages(conversation_id, sender_profile_id)
  where read_at is null and status <> 'deleted';

create trigger messages_set_updated_at
  before update on public.messages
  for each row execute function public.set_updated_at();

-- ---- 4.11 ratings ----------------------------------------------------------
create table public.ratings (
  id                   uuid        primary key default gen_random_uuid(),
  application_id       uuid        not null references public.applications(id) on delete cascade,
  offer_id             uuid        not null references public.offers(id)       on delete cascade,
  rater_profile_id     uuid        not null references public.profiles(id)     on delete cascade,
  rated_profile_id     uuid        not null references public.profiles(id)     on delete cascade,
  score                integer     not null,
  comment              text,
  is_public            boolean     not null default true,
  created_at           timestamptz not null default now(),
  updated_at           timestamptz not null default now(),

  constraint ratings_score_range       check (score between 1 and 5),
  constraint ratings_no_self_rating    check (rater_profile_id <> rated_profile_id),
  constraint ratings_comment_length    check (comment is null or char_length(comment) <= 2000),
  constraint ratings_unique_per_dir    unique (application_id, rater_profile_id, rated_profile_id)
);

create index ratings_rated_idx  on public.ratings(rated_profile_id);
create index ratings_rater_idx  on public.ratings(rater_profile_id);
create index ratings_offer_idx  on public.ratings(offer_id);

create trigger ratings_set_updated_at
  before update on public.ratings
  for each row execute function public.set_updated_at();

-- ---- 4.12 saved_offers -----------------------------------------------------
create table public.saved_offers (
  id                 uuid        primary key default gen_random_uuid(),
  helper_profile_id  uuid        not null references public.helper_profiles(profile_id) on delete cascade,
  offer_id           uuid        not null references public.offers(id)                  on delete cascade,
  created_at         timestamptz not null default now(),

  constraint saved_offers_unique unique (helper_profile_id, offer_id)
);

create index saved_offers_helper_idx on public.saved_offers(helper_profile_id);

-- ---- 4.13 notifications ----------------------------------------------------
create table public.notifications (
  id                    uuid        primary key default gen_random_uuid(),
  recipient_profile_id  uuid        not null references public.profiles(id) on delete cascade,
  type                  text        not null,
  title                 text        not null,
  body                  text,
  entity_type           text,
  entity_id             uuid,
  read_at               timestamptz,
  created_at            timestamptz not null default now(),

  constraint notifications_title_length check (char_length(title) between 1 and 160),
  constraint notifications_body_length  check (body is null or char_length(body) <= 1000),
  constraint notifications_type_length  check (char_length(type) between 2 and 80)
);

create index notifications_recipient_created_idx on public.notifications(recipient_profile_id, created_at desc);
create index notifications_unread_idx            on public.notifications(recipient_profile_id) where read_at is null;

-- ---- 4.14 admin_audit_log --------------------------------------------------
create table public.admin_audit_log (
  id                 uuid        primary key default gen_random_uuid(),
  actor_profile_id   uuid        references public.profiles(id) on delete set null,
  action             text        not null,
  entity_type        text        not null,
  entity_id          uuid,
  old_values         jsonb,
  new_values         jsonb,
  ip_address         inet,
  user_agent         text,
  created_at         timestamptz not null default now(),

  constraint admin_audit_log_action_length      check (char_length(action) between 3 and 120),
  constraint admin_audit_log_entity_type_length check (char_length(entity_type) between 2 and 120)
);

create index admin_audit_log_actor_idx   on public.admin_audit_log(actor_profile_id);
create index admin_audit_log_entity_idx  on public.admin_audit_log(entity_type, entity_id);
create index admin_audit_log_created_idx on public.admin_audit_log(created_at desc);

-- ---- 4.15 reports ----------------------------------------------------------
create table public.reports (
  id                      uuid        primary key default gen_random_uuid(),
  reporter_profile_id     uuid        not null references public.profiles(id) on delete cascade,
  reported_profile_id     uuid        references public.profiles(id) on delete set null,
  entity_type             text,
  entity_id               uuid,
  reason                  text        not null,
  details                 text,
  status                  text        not null default 'open',
  resolved_by_profile_id  uuid        references public.profiles(id) on delete set null,
  resolved_at             timestamptz,
  created_at              timestamptz not null default now(),
  updated_at              timestamptz not null default now(),

  constraint reports_status_check     check (status in ('open', 'in_review', 'resolved', 'dismissed')),
  constraint reports_reason_length    check (char_length(reason) between 3 and 160),
  constraint reports_details_length   check (details is null or char_length(details) <= 3000),
  constraint reports_resolution_consistency check (
    (status in ('resolved', 'dismissed') and resolved_at is not null) or
    (status in ('open', 'in_review'))
  )
);

create index reports_status_idx   on public.reports(status);
create index reports_reporter_idx on public.reports(reporter_profile_id);

create trigger reports_set_updated_at
  before update on public.reports
  for each row execute function public.set_updated_at();

-- =============================================================================
-- 5. BUSINESS-LOGIC TRIGGERS & FUNCTIONS
-- =============================================================================

-- ---- 5.0 Caller helpers (depend on public.profiles existing) ---------------
-- Returns the profile id for the calling auth user, NULL if anonymous / not yet onboarded.
create or replace function public.current_profile_id()
returns uuid
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select id
  from public.profiles
  where user_id = auth.uid()
  limit 1;
$$;

-- True when the caller has role='admin' and active status.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  select exists (
    select 1
    from public.profiles
    where user_id = auth.uid()
      and role = 'admin'
      and status = 'active'
  );
$$;

revoke execute on function public.is_admin()           from public;
revoke execute on function public.current_profile_id() from public;
grant  execute on function public.is_admin()           to authenticated;
grant  execute on function public.current_profile_id() to authenticated;

-- ---- 5.1 Auth → profile auto-create ---------------------------------------
-- Expects signup metadata in `raw_user_meta_data`:
--   { "role": "helper" | "organization", "display_name": "...", "slug": "..." }
-- The 'admin' role is NEVER set via this trigger — only via direct DB op by an existing admin.
create or replace function public.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_role         user_role;
  v_display_name text;
  v_slug         text;
  v_new_profile  uuid;
begin
  -- Default role to 'helper' if not supplied; never accept 'admin' from signup.
  v_role := coalesce(nullif(new.raw_user_meta_data->>'role', ''), 'helper')::user_role;
  if v_role = 'admin' then
    v_role := 'helper';
  end if;

  v_display_name := coalesce(
    nullif(new.raw_user_meta_data->>'display_name', ''),
    split_part(new.email, '@', 1)
  );

  v_slug := coalesce(
    nullif(new.raw_user_meta_data->>'slug', ''),
    lower(regexp_replace(v_display_name, '[^a-zA-Z0-9]+', '-', 'g'))
      || '-' || substr(replace(new.id::text, '-', ''), 1, 8)
  );
  v_slug := regexp_replace(v_slug, '(^-+|-+$)', '', 'g');
  if char_length(v_slug) < 3 then
    v_slug := 'user-' || substr(replace(new.id::text, '-', ''), 1, 8);
  end if;

  insert into public.profiles (user_id, role, display_name, slug)
  values (new.id, v_role, v_display_name, v_slug)
  returning id into v_new_profile;

  if v_role = 'helper' then
    insert into public.helper_profiles (profile_id) values (v_new_profile);
  elsif v_role = 'organization' then
    insert into public.organization_profiles (profile_id) values (v_new_profile);
  end if;

  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_auth_user();

-- ---- 5.2 Protect sensitive profile columns from user-driven updates --------
create or replace function public.tg_profiles_protect_columns()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
  -- Admins may change anything.
  if public.is_admin() then
    return new;
  end if;

  if new.role           is distinct from old.role           then raise exception 'role cannot be changed by user'           using errcode = '42501'; end if;
  if new.status         is distinct from old.status         then raise exception 'status cannot be changed by user'         using errcode = '42501'; end if;
  if new.user_id        is distinct from old.user_id        then raise exception 'user_id cannot be changed'                using errcode = '42501'; end if;
  if new.average_rating is distinct from old.average_rating then raise exception 'average_rating is system-managed'         using errcode = '42501'; end if;
  if new.rating_count   is distinct from old.rating_count   then raise exception 'rating_count is system-managed'           using errcode = '42501'; end if;
  if new.slug           is distinct from old.slug           then raise exception 'slug changes require admin'               using errcode = '42501'; end if;

  return new;
end;
$$;

create trigger profiles_protect_columns
  before update on public.profiles
  for each row execute function public.tg_profiles_protect_columns();

-- ---- 5.3 Offer status transition guard -------------------------------------
create or replace function public.tg_offers_validate_status_change()
returns trigger
language plpgsql
as $$
declare
  v_ok boolean := false;
begin
  if new.status = old.status then
    return new;
  end if;

  -- Allowed transitions
  v_ok := case
    when old.status = 'draft'     and new.status in ('published', 'cancelled', 'archived')                     then true
    when old.status = 'published' and new.status in ('paused', 'filled', 'completed', 'cancelled', 'archived') then true
    when old.status = 'paused'    and new.status in ('published', 'cancelled', 'archived')                     then true
    when old.status = 'filled'    and new.status in ('completed', 'cancelled', 'archived')                     then true
    when old.status = 'completed' and new.status in ('archived')                                               then true
    when old.status = 'cancelled' and new.status in ('archived')                                               then true
    else false
  end;

  if not v_ok then
    raise exception 'invalid offer status transition: % -> %', old.status, new.status using errcode = '23514';
  end if;

  if new.status = 'published' and new.published_at is null then new.published_at := now(); end if;
  if new.status = 'completed' and new.completed_at is null then new.completed_at := now(); end if;
  if new.status = 'cancelled' and new.cancelled_at is null then new.cancelled_at := now(); end if;

  return new;
end;
$$;

create trigger offers_validate_status_change
  before update of status on public.offers
  for each row execute function public.tg_offers_validate_status_change();

-- ---- 5.4 Application status transition guard + timestamps ------------------
create or replace function public.tg_applications_validate_status_change()
returns trigger
language plpgsql
as $$
declare
  v_ok boolean := false;
begin
  if new.status = old.status then
    return new;
  end if;

  v_ok := case
    when old.status = 'submitted'   and new.status in ('shortlisted','accepted','rejected','withdrawn','cancelled') then true
    when old.status = 'shortlisted' and new.status in ('accepted','rejected','withdrawn','cancelled')               then true
    when old.status = 'accepted'    and new.status in ('completed','cancelled','no_show','withdrawn')               then true
    when old.status = 'rejected'    and new.status in ('cancelled')                                                  then true
    else false
  end;

  if not v_ok then
    raise exception 'invalid application status transition: % -> %', old.status, new.status using errcode = '23514';
  end if;

  if new.status = 'accepted'  and new.accepted_at  is null then new.accepted_at  := now(); end if;
  if new.status = 'rejected'  and new.rejected_at  is null then new.rejected_at  := now(); end if;
  if new.status = 'withdrawn' and new.withdrawn_at is null then new.withdrawn_at := now(); end if;
  if new.status = 'completed' and new.completed_at is null then new.completed_at := now(); end if;

  return new;
end;
$$;

create trigger applications_validate_status_change
  before update of status on public.applications
  for each row execute function public.tg_applications_validate_status_change();

-- ---- 5.5 Recompute offer accepted_helpers_count ----------------------------
create or replace function public.recompute_offer_accepted_count(p_offer_id uuid)
returns void
language plpgsql
as $$
declare
  v_count int;
  v_max   int;
begin
  select count(*) into v_count
  from public.applications
  where offer_id = p_offer_id
    and status in ('accepted', 'completed');

  select max_helpers into v_max from public.offers where id = p_offer_id;

  update public.offers
    set accepted_helpers_count = v_count,
        status = case
                   when v_max is not null and v_count >= v_max and status = 'published' then 'filled'::offer_status
                   when v_max is not null and v_count <  v_max and status = 'filled'    then 'published'::offer_status
                   else status
                 end
  where id = p_offer_id;
end;
$$;

create or replace function public.tg_applications_status_side_effects()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'INSERT' then
    perform public.recompute_offer_accepted_count(new.offer_id);
  elsif tg_op = 'UPDATE' then
    if new.status is distinct from old.status or new.offer_id is distinct from old.offer_id then
      perform public.recompute_offer_accepted_count(new.offer_id);
      if new.offer_id is distinct from old.offer_id then
        perform public.recompute_offer_accepted_count(old.offer_id);
      end if;
    end if;
  elsif tg_op = 'DELETE' then
    perform public.recompute_offer_accepted_count(old.offer_id);
  end if;
  return null;
end;
$$;

create trigger applications_status_side_effects
  after insert or update or delete on public.applications
  for each row execute function public.tg_applications_status_side_effects();

-- ---- 5.6 Recompute profile rating aggregates -------------------------------
create or replace function public.recompute_profile_rating(p_profile_id uuid)
returns void
language plpgsql
as $$
begin
  update public.profiles p
    set average_rating = coalesce(agg.avg_score, 0),
        rating_count   = coalesce(agg.cnt, 0)
  from (
    select avg(score)::numeric(3,2) as avg_score, count(*)::int as cnt
    from public.ratings
    where rated_profile_id = p_profile_id
  ) agg
  where p.id = p_profile_id;
end;
$$;

create or replace function public.tg_ratings_recompute()
returns trigger
language plpgsql
as $$
begin
  if tg_op = 'DELETE' then
    perform public.recompute_profile_rating(old.rated_profile_id);
    return old;
  else
    perform public.recompute_profile_rating(new.rated_profile_id);
    if tg_op = 'UPDATE' and new.rated_profile_id is distinct from old.rated_profile_id then
      perform public.recompute_profile_rating(old.rated_profile_id);
    end if;
    return new;
  end if;
end;
$$;

create trigger ratings_recompute_aggregates
  after insert or update or delete on public.ratings
  for each row execute function public.tg_ratings_recompute();

-- ---- 5.7 Validate document share ownership ---------------------------------
create or replace function public.tg_validate_document_share()
returns trigger
language plpgsql
as $$
declare
  v_app_helper uuid;
  v_doc_helper uuid;
  v_doc_status document_status;
  v_doc_expires date;
begin
  select helper_profile_id into v_app_helper from public.applications    where id = new.application_id;
  select helper_profile_id, status, expires_at into v_doc_helper, v_doc_status, v_doc_expires
    from public.helper_documents where id = new.document_id;

  if v_app_helper is null or v_doc_helper is null then
    raise exception 'application or document not found' using errcode = '23503';
  end if;
  if v_app_helper <> v_doc_helper then
    raise exception 'document does not belong to the helper of this application' using errcode = '42501';
  end if;
  if v_doc_status <> 'active' then
    raise exception 'document is not active (status=%)', v_doc_status using errcode = '23514';
  end if;
  if v_doc_expires is not null and v_doc_expires < current_date then
    raise exception 'document is expired' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger application_document_shares_validate
  before insert on public.application_document_shares
  for each row execute function public.tg_validate_document_share();

-- ---- 5.8 Ensure conversation for application -------------------------------
create or replace function public.tg_ensure_conversation_for_application()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_org_id uuid;
begin
  select organization_profile_id into v_org_id from public.offers where id = new.offer_id;

  insert into public.conversations (application_id, offer_id, helper_profile_id, organization_profile_id)
  values (new.id, new.offer_id, new.helper_profile_id, v_org_id)
  on conflict (application_id) do nothing;

  return new;
end;
$$;

create trigger applications_ensure_conversation
  after insert on public.applications
  for each row execute function public.tg_ensure_conversation_for_application();

-- ---- 5.9 Validate conversation consistency --------------------------------
create or replace function public.tg_validate_conversation_consistency()
returns trigger
language plpgsql
as $$
declare
  v_app public.applications;
  v_org uuid;
begin
  select * into v_app from public.applications where id = new.application_id;
  if not found then
    raise exception 'application not found for conversation' using errcode = '23503';
  end if;

  select organization_profile_id into v_org from public.offers where id = v_app.offer_id;
  if v_org is null then
    raise exception 'offer not found for conversation application' using errcode = '23503';
  end if;

  if new.offer_id <> v_app.offer_id then
    raise exception 'conversation offer does not match application offer' using errcode = '23514';
  end if;
  if new.helper_profile_id <> v_app.helper_profile_id then
    raise exception 'conversation helper does not match application helper' using errcode = '23514';
  end if;
  if new.organization_profile_id <> v_org then
    raise exception 'conversation organization does not match offer owner' using errcode = '23514';
  end if;

  return new;
end;
$$;

create trigger conversations_validate_consistency
  before insert or update on public.conversations
  for each row execute function public.tg_validate_conversation_consistency();

-- ---- 5.10 Guard message updates -------------------------------------------
create or replace function public.tg_messages_guard_update()
returns trigger
language plpgsql
as $$
begin
  if public.is_admin() then
    return new;
  end if;

  if new.conversation_id <> old.conversation_id
     or new.sender_profile_id <> old.sender_profile_id
     or new.body <> old.body then
    raise exception 'message content and ownership fields are immutable' using errcode = '42501';
  end if;

  if new.status <> 'read' or new.read_at is null then
    raise exception 'participants may only mark messages as read' using errcode = '42501';
  end if;

  return new;
end;
$$;

create trigger messages_guard_update
  before update on public.messages
  for each row execute function public.tg_messages_guard_update();

-- ---- 5.11 Message side effects --------------------------------------------
create or replace function public.tg_messages_after_insert_side_effects()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_conv public.conversations;
  v_recipient uuid;
  v_sender_name text;
begin
  select * into v_conv from public.conversations where id = new.conversation_id;
  if not found then
    raise exception 'conversation not found for message' using errcode = '23503';
  end if;

  if new.sender_profile_id = v_conv.helper_profile_id then
    v_recipient := v_conv.organization_profile_id;
  elsif new.sender_profile_id = v_conv.organization_profile_id then
    v_recipient := v_conv.helper_profile_id;
  else
    raise exception 'message sender is not a conversation participant' using errcode = '42501';
  end if;

  update public.conversations
    set last_message_at = new.created_at,
        updated_at = now()
    where id = new.conversation_id;

  select display_name into v_sender_name from public.profiles where id = new.sender_profile_id;

  insert into public.notifications (
    recipient_profile_id,
    type,
    title,
    body,
    entity_type,
    entity_id,
    created_at
  )
  values (
    v_recipient,
    'message',
    left('Neue Nachricht von ' || coalesce(v_sender_name, 'ActNow'), 160),
    left(new.body, 1000),
    'conversation',
    new.conversation_id,
    new.created_at
  );

  return new;
end;
$$;

create trigger messages_after_insert_side_effects
  after insert on public.messages
  for each row execute function public.tg_messages_after_insert_side_effects();

-- =============================================================================
-- 6. VIEWS
-- =============================================================================

create or replace view public.public_profiles_view as
  select
    p.id,
    p.role,
    p.status,
    p.display_name,
    p.slug,
    p.avatar_url,
    p.bio,
    p.city,
    p.country_code,
    p.website_url,
    p.average_rating,
    p.rating_count,
    p.created_at,
    op.organization_type,
    op.is_verified
  from public.profiles p
  left join public.organization_profiles op on op.profile_id = p.id
  where p.status = 'active';

create or replace view public.published_offers_view as
  select
    o.*,
    op.organization_type,
    op.is_verified,
    pr.display_name   as organization_display_name,
    pr.slug           as organization_slug,
    pr.avatar_url     as organization_avatar_url,
    pr.average_rating as organization_average_rating,
    pr.rating_count   as organization_rating_count
  from public.offers o
  join public.organization_profiles op on op.profile_id = o.organization_profile_id
  join public.profiles              pr on pr.id         = op.profile_id
  where o.status = 'published'
    and (o.application_deadline is null or o.application_deadline >= now());

create or replace view public.organization_rating_summary_view as
  select
    op.profile_id              as organization_profile_id,
    coalesce(avg(r.score), 0)::numeric(3,2) as average_rating,
    count(r.id)::int           as rating_count,
    max(r.created_at)          as last_rating_at
  from public.organization_profiles op
  left join public.ratings r on r.rated_profile_id = op.profile_id
  group by op.profile_id;

create or replace view public.helper_rating_summary_view as
  select
    hp.profile_id                                            as helper_profile_id,
    coalesce(avg(r.score), 0)::numeric(3,2)                  as average_rating,
    count(r.id)::int                                         as rating_count,
    (select count(*) from public.applications a
       where a.helper_profile_id = hp.profile_id and a.status = 'completed')::int as completed_applications_count,
    (select count(*) from public.applications a
       where a.helper_profile_id = hp.profile_id and a.status = 'no_show')::int   as no_show_count
  from public.helper_profiles hp
  left join public.ratings r on r.rated_profile_id = hp.profile_id
  group by hp.profile_id;

-- =============================================================================
-- 7. RPC FUNCTIONS
-- =============================================================================

-- ---- 7.1 search_offers -----------------------------------------------------
create or replace function public.search_offers(
  p_location_name   text                 default null,
  p_available_from  timestamptz          default null,
  p_available_to    timestamptz          default null,
  p_offer_type      public.offer_type    default null,
  p_tags            text[]               default null,
  p_limit           int                  default 20,
  p_offset          int                  default 0
)
returns table (
  id                          uuid,
  organization_profile_id     uuid,
  title                       text,
  description                 text,
  offer_type                  public.offer_type,
  status                      public.offer_status,
  category                    text,
  skills_required             text[],
  city                        text,
  is_remote                   boolean,
  starts_at                   timestamptz,
  ends_at                     timestamptz,
  application_deadline        timestamptz,
  published_at                timestamptz,
  organization_display_name   text,
  organization_avatar_url     text,
  organization_average_rating numeric,
  organization_rating_count   integer,
  has_applied                 boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with caller as (
    select hp.profile_id as helper_profile_id
    from public.profiles p
    join public.helper_profiles hp on hp.profile_id = p.id
    where p.user_id = auth.uid()
  )
  select
    o.id, o.organization_profile_id, o.title, o.description, o.offer_type, o.status,
    o.category, o.skills_required, o.city, o.is_remote,
    o.starts_at, o.ends_at, o.application_deadline, o.published_at,
    pr.display_name,
    pr.avatar_url,
    pr.average_rating,
    pr.rating_count,
    exists (
      select 1
      from public.applications a, caller c
      where a.offer_id = o.id and a.helper_profile_id = c.helper_profile_id
    ) as has_applied
  from public.offers o
  join public.organization_profiles op on op.profile_id = o.organization_profile_id
  join public.profiles              pr on pr.id         = op.profile_id
  where o.status = 'published'
    and (p_location_name  is null or o.city ilike '%' || p_location_name || '%' or o.is_remote = true)
    and (p_available_from is null or o.starts_at is null or o.starts_at >= p_available_from)
    and (p_available_to   is null or o.ends_at   is null or o.ends_at   <= p_available_to)
    and (p_offer_type     is null or o.offer_type = p_offer_type)
    and (p_tags           is null or o.skills_required && p_tags)
    and (o.application_deadline is null or o.application_deadline >= now())
  order by o.published_at desc nulls last, o.starts_at asc nulls last
  limit greatest(p_limit, 1)
  offset greatest(p_offset, 0);
$$;

-- ---- 7.2 publish_offer -----------------------------------------------------
create or replace function public.publish_offer(p_offer_id uuid)
returns public.offers
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_offer public.offers;
  v_owner uuid;
begin
  select * into v_offer from public.offers where id = p_offer_id for update;
  if not found then raise exception 'offer not found' using errcode = '23503'; end if;

  v_owner := v_offer.organization_profile_id;
  if not (public.is_admin() or v_owner = public.current_profile_id()) then
    raise exception 'not authorized to publish this offer' using errcode = '42501';
  end if;

  if v_offer.status not in ('draft', 'paused') then
    raise exception 'offer cannot be published from status %', v_offer.status using errcode = '23514';
  end if;

  update public.offers
    set status = 'published',
        published_at = coalesce(published_at, now())
    where id = p_offer_id
    returning * into v_offer;

  return v_offer;
end;
$$;

-- ---- 7.3 accept_application ------------------------------------------------
create or replace function public.accept_application(p_application_id uuid)
returns public.applications
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_app    public.applications;
  v_offer  public.offers;
begin
  select * into v_app from public.applications where id = p_application_id for update;
  if not found then raise exception 'application not found' using errcode = '23503'; end if;

  select * into v_offer from public.offers where id = v_app.offer_id for update;
  if not found then raise exception 'offer not found' using errcode = '23503'; end if;

  if not (public.is_admin() or v_offer.organization_profile_id = public.current_profile_id()) then
    raise exception 'not authorized to accept this application' using errcode = '42501';
  end if;

  if v_offer.status not in ('published','paused','filled') then
    raise exception 'offer is not open for acceptance (status=%)', v_offer.status using errcode = '23514';
  end if;

  if v_app.status not in ('submitted', 'shortlisted') then
    raise exception 'application cannot be accepted from status %', v_app.status using errcode = '23514';
  end if;

  if v_offer.max_helpers is not null and v_offer.accepted_helpers_count >= v_offer.max_helpers then
    raise exception 'offer capacity reached' using errcode = '23514';
  end if;

  update public.applications
    set status = 'accepted', accepted_at = now()
    where id = p_application_id
    returning * into v_app;

  return v_app;
end;
$$;

-- ---- 7.4 reject_application ------------------------------------------------
create or replace function public.reject_application(p_application_id uuid, p_reason text default null)
returns public.applications
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_app   public.applications;
  v_offer public.offers;
begin
  select * into v_app from public.applications where id = p_application_id for update;
  if not found then raise exception 'application not found' using errcode = '23503'; end if;

  select * into v_offer from public.offers where id = v_app.offer_id;
  if not (public.is_admin() or v_offer.organization_profile_id = public.current_profile_id()) then
    raise exception 'not authorized to reject this application' using errcode = '42501';
  end if;

  if v_app.status not in ('submitted', 'shortlisted') then
    raise exception 'application cannot be rejected from status %', v_app.status using errcode = '23514';
  end if;

  update public.applications
    set status = 'rejected',
        rejected_at = now(),
        organization_note = coalesce(p_reason, organization_note)
    where id = p_application_id
    returning * into v_app;

  return v_app;
end;
$$;

-- ---- 7.5 withdraw_application ----------------------------------------------
create or replace function public.withdraw_application(p_application_id uuid)
returns public.applications
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_app public.applications;
begin
  select * into v_app from public.applications where id = p_application_id for update;
  if not found then raise exception 'application not found' using errcode = '23503'; end if;

  if not (public.is_admin() or v_app.helper_profile_id = public.current_profile_id()) then
    raise exception 'not authorized to withdraw this application' using errcode = '42501';
  end if;

  if v_app.status not in ('submitted', 'shortlisted', 'accepted') then
    raise exception 'application cannot be withdrawn from status %', v_app.status using errcode = '23514';
  end if;

  update public.applications
    set status = 'withdrawn', withdrawn_at = now()
    where id = p_application_id
    returning * into v_app;

  return v_app;
end;
$$;

-- ---- 7.6 complete_application ----------------------------------------------
create or replace function public.complete_application(p_application_id uuid)
returns public.applications
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_app   public.applications;
  v_offer public.offers;
begin
  select * into v_app from public.applications where id = p_application_id for update;
  if not found then raise exception 'application not found' using errcode = '23503'; end if;

  select * into v_offer from public.offers where id = v_app.offer_id;

  if not (public.is_admin() or v_offer.organization_profile_id = public.current_profile_id()) then
    raise exception 'not authorized to complete this application' using errcode = '42501';
  end if;

  if v_app.status <> 'accepted' then
    raise exception 'only accepted applications can be completed (status=%)', v_app.status using errcode = '23514';
  end if;

  update public.applications
    set status = 'completed', completed_at = now()
    where id = p_application_id
    returning * into v_app;

  return v_app;
end;
$$;

-- ---- 7.7 create_conversation_for_application -------------------------------
create or replace function public.create_conversation_for_application(p_application_id uuid)
returns public.conversations
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_app  public.applications;
  v_org  uuid;
  v_conv public.conversations;
  v_me   uuid := public.current_profile_id();
begin
  select * into v_app from public.applications where id = p_application_id;
  if not found then raise exception 'application not found' using errcode = '23503'; end if;

  select organization_profile_id into v_org from public.offers where id = v_app.offer_id;

  if not (public.is_admin() or v_me = v_app.helper_profile_id or v_me = v_org) then
    raise exception 'not authorized for this application' using errcode = '42501';
  end if;

  insert into public.conversations (application_id, offer_id, helper_profile_id, organization_profile_id)
  values (p_application_id, v_app.offer_id, v_app.helper_profile_id, v_org)
  on conflict (application_id) do update set updated_at = now()
  returning * into v_conv;

  return v_conv;
end;
$$;

-- ---- 7.8 list_community_conversations -------------------------------------
create or replace function public.list_community_conversations(
  p_limit  int default 50,
  p_offset int default 0
)
returns table (
  conversation_id                  uuid,
  application_id                   uuid,
  offer_id                         uuid,
  offer_title                      text,
  helper_profile_id                uuid,
  organization_profile_id          uuid,
  counterparty_profile_id          uuid,
  counterparty_display_name        text,
  counterparty_avatar_url          text,
  last_message_body                text,
  last_message_sender_profile_id   uuid,
  last_message_at                  timestamptz,
  unread_count                     integer,
  created_at                       timestamptz,
  updated_at                       timestamptz
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with me as (
    select public.current_profile_id() as profile_id, public.is_admin() as admin
  ),
  visible_conversations as (
    select c.*, o.title as offer_title
    from public.conversations c
    join public.offers o on o.id = c.offer_id
    cross join me
    where me.admin
       or c.helper_profile_id = me.profile_id
       or c.organization_profile_id = me.profile_id
  )
  select
    c.id as conversation_id,
    c.application_id,
    c.offer_id,
    c.offer_title,
    c.helper_profile_id,
    c.organization_profile_id,
    case
      when c.helper_profile_id = me.profile_id then c.organization_profile_id
      else c.helper_profile_id
    end as counterparty_profile_id,
    p.display_name as counterparty_display_name,
    p.avatar_url as counterparty_avatar_url,
    lm.body as last_message_body,
    lm.sender_profile_id as last_message_sender_profile_id,
    coalesce(lm.created_at, c.last_message_at) as last_message_at,
    coalesce(uc.unread_count, 0)::integer as unread_count,
    c.created_at,
    c.updated_at
  from visible_conversations c
  cross join me
  join public.profiles p
    on p.id = case
      when c.helper_profile_id = me.profile_id then c.organization_profile_id
      else c.helper_profile_id
    end
  left join lateral (
    select m.body, m.sender_profile_id, m.created_at
    from public.messages m
    where m.conversation_id = c.id
      and m.status <> 'deleted'
    order by m.created_at desc
    limit 1
  ) lm on true
  left join lateral (
    select count(*)::integer as unread_count
    from public.messages m
    where m.conversation_id = c.id
      and m.sender_profile_id <> me.profile_id
      and m.read_at is null
      and m.status <> 'deleted'
  ) uc on true
  order by coalesce(lm.created_at, c.last_message_at, c.updated_at, c.created_at) desc
  limit least(greatest(coalesce(p_limit, 50), 1), 100)
  offset greatest(coalesce(p_offset, 0), 0);
$$;

-- ---- 7.9 get_community_summary --------------------------------------------
create or replace function public.get_community_summary()
returns table (
  unread_messages       integer,
  unread_notifications  integer,
  total_unread          integer
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
  with me as (
    select public.current_profile_id() as profile_id, public.is_admin() as admin
  ),
  unread_messages as (
    select count(*)::integer as n
    from public.messages m
    join public.conversations c on c.id = m.conversation_id
    cross join me
    where m.read_at is null
      and m.status <> 'deleted'
      and m.sender_profile_id <> me.profile_id
      and (
        me.admin
        or c.helper_profile_id = me.profile_id
        or c.organization_profile_id = me.profile_id
      )
  ),
  unread_notifications as (
    select count(*)::integer as n
    from public.notifications n
    cross join me
    where n.recipient_profile_id = me.profile_id
      and n.read_at is null
  )
  select
    unread_messages.n,
    unread_notifications.n,
    unread_messages.n + unread_notifications.n
  from unread_messages, unread_notifications;
$$;

-- ---- 7.10 mark_conversation_read ------------------------------------------
create or replace function public.mark_conversation_read(p_conversation_id uuid)
returns integer
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_me uuid := public.current_profile_id();
  v_marked integer := 0;
begin
  if v_me is null then
    raise exception 'authenticated profile not found' using errcode = '42501';
  end if;

  if not exists (
    select 1
    from public.conversations c
    where c.id = p_conversation_id
      and (
        public.is_admin()
        or c.helper_profile_id = v_me
        or c.organization_profile_id = v_me
      )
  ) then
    raise exception 'not authorized for this conversation' using errcode = '42501';
  end if;

  update public.messages
    set status = 'read',
        read_at = coalesce(read_at, now())
    where conversation_id = p_conversation_id
      and sender_profile_id <> v_me
      and read_at is null
      and status <> 'deleted';

  get diagnostics v_marked = row_count;

  update public.notifications
    set read_at = coalesce(read_at, now())
    where recipient_profile_id = v_me
      and type = 'message'
      and entity_type = 'conversation'
      and entity_id = p_conversation_id
      and read_at is null;

  return v_marked;
end;
$$;

-- Lock down RPC execution
revoke execute on function public.search_offers(text, timestamptz, timestamptz, public.offer_type, text[], int, int) from public;
revoke execute on function public.publish_offer(uuid)                          from public;
revoke execute on function public.accept_application(uuid)                     from public;
revoke execute on function public.reject_application(uuid, text)               from public;
revoke execute on function public.withdraw_application(uuid)                   from public;
revoke execute on function public.complete_application(uuid)                   from public;
revoke execute on function public.create_conversation_for_application(uuid)    from public;
revoke execute on function public.list_community_conversations(int, int)       from public;
revoke execute on function public.get_community_summary()                      from public;
revoke execute on function public.mark_conversation_read(uuid)                 from public;

grant execute on function public.search_offers(text, timestamptz, timestamptz, public.offer_type, text[], int, int) to authenticated;
grant execute on function public.publish_offer(uuid)                          to authenticated;
grant execute on function public.accept_application(uuid)                     to authenticated;
grant execute on function public.reject_application(uuid, text)               to authenticated;
grant execute on function public.withdraw_application(uuid)                   to authenticated;
grant execute on function public.complete_application(uuid)                   to authenticated;
grant execute on function public.create_conversation_for_application(uuid)    to authenticated;
grant execute on function public.list_community_conversations(int, int)       to authenticated;
grant execute on function public.get_community_summary()                      to authenticated;
grant execute on function public.mark_conversation_read(uuid)                 to authenticated;

-- =============================================================================
-- 8. ROW LEVEL SECURITY
-- =============================================================================

alter table public.profiles                     enable row level security;
alter table public.helper_profiles              enable row level security;
alter table public.organization_profiles        enable row level security;
alter table public.offers                       enable row level security;
alter table public.offer_recurrences            enable row level security;
alter table public.applications                 enable row level security;
alter table public.helper_documents             enable row level security;
alter table public.application_document_shares  enable row level security;
alter table public.conversations                enable row level security;
alter table public.messages                     enable row level security;
alter table public.ratings                      enable row level security;
alter table public.saved_offers                 enable row level security;
alter table public.notifications                enable row level security;
alter table public.admin_audit_log              enable row level security;
alter table public.reports                      enable row level security;

-- ---- 8.1 profiles ----------------------------------------------------------
create policy profiles_select_own_or_active
  on public.profiles for select
  using (
    public.is_admin()
    or user_id = auth.uid()
    or status = 'active'
  );

create policy profiles_insert_self
  on public.profiles for insert
  with check (
    public.is_admin()
    or user_id = auth.uid()
  );

create policy profiles_update_self
  on public.profiles for update
  using (public.is_admin() or user_id = auth.uid())
  with check (public.is_admin() or user_id = auth.uid());

create policy profiles_delete_admin
  on public.profiles for delete
  using (public.is_admin());

-- ---- 8.2 helper_profiles ---------------------------------------------------
create policy helper_profiles_select
  on public.helper_profiles for select
  using (
    public.is_admin()
    or profile_id = public.current_profile_id()
    or exists (
      select 1 from public.profiles p
      where p.id = helper_profiles.profile_id and p.status = 'active'
    )
  );

create policy helper_profiles_modify_own
  on public.helper_profiles for all
  using (public.is_admin() or profile_id = public.current_profile_id())
  with check (public.is_admin() or profile_id = public.current_profile_id());

-- ---- 8.3 organization_profiles ---------------------------------------------
create policy organization_profiles_select
  on public.organization_profiles for select
  using (
    public.is_admin()
    or profile_id = public.current_profile_id()
    or exists (
      select 1 from public.profiles p
      where p.id = organization_profiles.profile_id and p.status = 'active'
    )
  );

create policy organization_profiles_modify_own
  on public.organization_profiles for all
  using (public.is_admin() or profile_id = public.current_profile_id())
  with check (public.is_admin() or profile_id = public.current_profile_id());

-- ---- 8.4 offers ------------------------------------------------------------
create policy offers_select
  on public.offers for select
  using (
    public.is_admin()
    or status in ('published','paused','filled','completed')
    or organization_profile_id = public.current_profile_id()
  );

create policy offers_insert_owning_org
  on public.offers for insert
  with check (
    public.is_admin()
    or organization_profile_id = public.current_profile_id()
  );

create policy offers_update_owning_org
  on public.offers for update
  using (public.is_admin() or organization_profile_id = public.current_profile_id())
  with check (public.is_admin() or organization_profile_id = public.current_profile_id());

create policy offers_delete_owning_org
  on public.offers for delete
  using (public.is_admin() or organization_profile_id = public.current_profile_id());

-- ---- 8.5 offer_recurrences -------------------------------------------------
create policy offer_recurrences_select
  on public.offer_recurrences for select
  using (
    public.is_admin()
    or exists (
      select 1 from public.offers o
      where o.id = offer_recurrences.offer_id
        and (o.status in ('published','paused','filled','completed')
             or o.organization_profile_id = public.current_profile_id())
    )
  );

create policy offer_recurrences_modify
  on public.offer_recurrences for all
  using (
    public.is_admin()
    or exists (
      select 1 from public.offers o
      where o.id = offer_recurrences.offer_id
        and o.organization_profile_id = public.current_profile_id()
    )
  )
  with check (
    public.is_admin()
    or exists (
      select 1 from public.offers o
      where o.id = offer_recurrences.offer_id
        and o.organization_profile_id = public.current_profile_id()
    )
  );

-- ---- 8.6 applications ------------------------------------------------------
create policy applications_select
  on public.applications for select
  using (
    public.is_admin()
    or helper_profile_id = public.current_profile_id()
    or exists (
      select 1 from public.offers o
      where o.id = applications.offer_id
        and o.organization_profile_id = public.current_profile_id()
    )
  );

create policy applications_insert_helper
  on public.applications for insert
  with check (
    public.is_admin()
    or helper_profile_id = public.current_profile_id()
  );

create policy applications_update_participants
  on public.applications for update
  using (
    public.is_admin()
    or helper_profile_id = public.current_profile_id()
    or exists (
      select 1 from public.offers o
      where o.id = applications.offer_id
        and o.organization_profile_id = public.current_profile_id()
    )
  )
  with check (
    public.is_admin()
    or helper_profile_id = public.current_profile_id()
    or exists (
      select 1 from public.offers o
      where o.id = applications.offer_id
        and o.organization_profile_id = public.current_profile_id()
    )
  );

create policy applications_delete_admin
  on public.applications for delete
  using (public.is_admin());

-- ---- 8.7 helper_documents --------------------------------------------------
create policy helper_documents_select
  on public.helper_documents for select
  using (
    public.is_admin()
    or helper_profile_id = public.current_profile_id()
    or exists (
      select 1
      from public.application_document_shares s
      join public.applications a on a.id = s.application_id
      join public.offers       o on o.id = a.offer_id
      where s.document_id = helper_documents.id
        and s.revoked_at is null
        and o.organization_profile_id = public.current_profile_id()
    )
  );

create policy helper_documents_modify_owner
  on public.helper_documents for all
  using (public.is_admin() or helper_profile_id = public.current_profile_id())
  with check (public.is_admin() or helper_profile_id = public.current_profile_id());

-- ---- 8.8 application_document_shares ---------------------------------------
create policy application_document_shares_select
  on public.application_document_shares for select
  using (
    public.is_admin()
    or exists (
      select 1 from public.applications a
      where a.id = application_document_shares.application_id
        and a.helper_profile_id = public.current_profile_id()
    )
    or exists (
      select 1 from public.applications a
      join public.offers o on o.id = a.offer_id
      where a.id = application_document_shares.application_id
        and o.organization_profile_id = public.current_profile_id()
    )
  );

create policy application_document_shares_insert_helper
  on public.application_document_shares for insert
  with check (
    public.is_admin()
    or exists (
      select 1 from public.applications a
      where a.id = application_document_shares.application_id
        and a.helper_profile_id = public.current_profile_id()
    )
  );

create policy application_document_shares_update_helper
  on public.application_document_shares for update
  using (
    public.is_admin()
    or exists (
      select 1 from public.applications a
      where a.id = application_document_shares.application_id
        and a.helper_profile_id = public.current_profile_id()
    )
  )
  with check (
    public.is_admin()
    or exists (
      select 1 from public.applications a
      where a.id = application_document_shares.application_id
        and a.helper_profile_id = public.current_profile_id()
    )
  );

create policy application_document_shares_delete_helper
  on public.application_document_shares for delete
  using (
    public.is_admin()
    or exists (
      select 1 from public.applications a
      where a.id = application_document_shares.application_id
        and a.helper_profile_id = public.current_profile_id()
    )
  );

-- ---- 8.9 conversations -----------------------------------------------------
create policy conversations_select_participants
  on public.conversations for select
  using (
    public.is_admin()
    or helper_profile_id       = public.current_profile_id()
    or organization_profile_id = public.current_profile_id()
  );

create policy conversations_insert_participants
  on public.conversations for insert
  with check (
    public.is_admin()
    or helper_profile_id       = public.current_profile_id()
    or organization_profile_id = public.current_profile_id()
  );

create policy conversations_update_admin
  on public.conversations for update
  using (public.is_admin())
  with check (public.is_admin());

-- ---- 8.10 messages ---------------------------------------------------------
create policy messages_select_participants
  on public.messages for select
  using (
    public.is_admin()
    or exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.helper_profile_id = public.current_profile_id()
             or c.organization_profile_id = public.current_profile_id())
    )
  );

create policy messages_insert_participants
  on public.messages for insert
  with check (
    sender_profile_id = public.current_profile_id()
    and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.helper_profile_id = public.current_profile_id()
             or c.organization_profile_id = public.current_profile_id())
    )
  );

-- Recipient may mark a message read (set status, read_at). Body is immutable for non-admins
-- (enforced here by only allowing UPDATE if caller is NOT the sender or is admin).
create policy messages_update_recipient_mark_read
  on public.messages for update
  using (
    public.is_admin()
    or (
      sender_profile_id <> public.current_profile_id()
      and exists (
        select 1 from public.conversations c
        where c.id = messages.conversation_id
          and (c.helper_profile_id = public.current_profile_id()
               or c.organization_profile_id = public.current_profile_id())
      )
    )
  )
  with check (
    public.is_admin()
    or (
      sender_profile_id <> public.current_profile_id()
      and exists (
        select 1 from public.conversations c
        where c.id = messages.conversation_id
          and (c.helper_profile_id = public.current_profile_id()
               or c.organization_profile_id = public.current_profile_id())
      )
    )
  );

-- ---- 8.11 ratings ----------------------------------------------------------
create policy ratings_select
  on public.ratings for select
  using (
    public.is_admin()
    or is_public = true
    or rater_profile_id = public.current_profile_id()
    or rated_profile_id = public.current_profile_id()
  );

-- INSERT: only after application is 'completed' AND rater is a legitimate participant
-- AND rated is the counterpart. Uniqueness is enforced by table constraint.
create policy ratings_insert_after_completion
  on public.ratings for insert
  with check (
    public.is_admin()
    or (
      rater_profile_id = public.current_profile_id()
      and exists (
        select 1
        from public.applications a
        join public.offers o on o.id = a.offer_id
        where a.id = ratings.application_id
          and a.status = 'completed'
          and (
            (rater_profile_id = a.helper_profile_id        and rated_profile_id = o.organization_profile_id) or
            (rater_profile_id = o.organization_profile_id  and rated_profile_id = a.helper_profile_id)
          )
      )
    )
  );

create policy ratings_update_own
  on public.ratings for update
  using (public.is_admin() or rater_profile_id = public.current_profile_id())
  with check (public.is_admin() or rater_profile_id = public.current_profile_id());

create policy ratings_delete_admin_or_owner
  on public.ratings for delete
  using (public.is_admin() or rater_profile_id = public.current_profile_id());

-- ---- 8.12 saved_offers -----------------------------------------------------
create policy saved_offers_modify_own
  on public.saved_offers for all
  using (public.is_admin() or helper_profile_id = public.current_profile_id())
  with check (public.is_admin() or helper_profile_id = public.current_profile_id());

-- ---- 8.13 notifications ----------------------------------------------------
create policy notifications_select_own
  on public.notifications for select
  using (public.is_admin() or recipient_profile_id = public.current_profile_id());

create policy notifications_update_own
  on public.notifications for update
  using (public.is_admin() or recipient_profile_id = public.current_profile_id())
  with check (public.is_admin() or recipient_profile_id = public.current_profile_id());

create policy notifications_delete_own
  on public.notifications for delete
  using (public.is_admin() or recipient_profile_id = public.current_profile_id());

-- Inserts happen via triggers/RPCs running as definer; no client INSERT policy.

-- ---- 8.14 admin_audit_log --------------------------------------------------
create policy admin_audit_log_select_admin
  on public.admin_audit_log for select
  using (public.is_admin());

-- ---- 8.15 reports ----------------------------------------------------------
create policy reports_select
  on public.reports for select
  using (public.is_admin() or reporter_profile_id = public.current_profile_id());

create policy reports_insert_self
  on public.reports for insert
  with check (reporter_profile_id = public.current_profile_id());

create policy reports_update_admin
  on public.reports for update
  using (public.is_admin())
  with check (public.is_admin());

-- =============================================================================
-- 9. STORAGE BUCKETS & POLICIES
-- =============================================================================

-- Buckets ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('avatars',          'avatars',          true,  5242880,
    array['image/jpeg','image/png','image/webp']),
  ('helper-documents', 'helper-documents', false, 20971520,
    array['application/pdf','image/jpeg','image/png']),
  ('offer-images',     'offer-images',     true,  5242880,
    array['image/jpeg','image/png','image/webp'])
on conflict (id) do update
  set public             = excluded.public,
      file_size_limit    = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- ---- 9.1 avatars (public read, owner write) -------------------------------
-- Path convention: `profiles/{profile_id}/...`
create policy "avatars_read_public"
  on storage.objects for select
  using (bucket_id = 'avatars');

create policy "avatars_insert_own"
  on storage.objects for insert
  with check (
    bucket_id = 'avatars'
    and split_part(name, '/', 1) = 'profiles'
    and exists (
      select 1 from public.profiles p
      where p.id::text = split_part(name, '/', 2)
        and (p.user_id = auth.uid() or public.is_admin())
    )
  );

create policy "avatars_update_own"
  on storage.objects for update
  using (
    bucket_id = 'avatars'
    and exists (
      select 1 from public.profiles p
      where p.id::text = split_part(name, '/', 2)
        and (p.user_id = auth.uid() or public.is_admin())
    )
  );

create policy "avatars_delete_own"
  on storage.objects for delete
  using (
    bucket_id = 'avatars'
    and exists (
      select 1 from public.profiles p
      where p.id::text = split_part(name, '/', 2)
        and (p.user_id = auth.uid() or public.is_admin())
    )
  );

-- ---- 9.2 offer-images (public read, owning-org write) ---------------------
-- Path convention: `offers/{offer_id}/...`
create policy "offer_images_read_public"
  on storage.objects for select
  using (bucket_id = 'offer-images');

create policy "offer_images_write_owning_org"
  on storage.objects for all
  using (
    bucket_id = 'offer-images'
    and exists (
      select 1 from public.offers o
      where o.id::text = split_part(name, '/', 2)
        and (o.organization_profile_id = public.current_profile_id() or public.is_admin())
    )
  )
  with check (
    bucket_id = 'offer-images'
    and exists (
      select 1 from public.offers o
      where o.id::text = split_part(name, '/', 2)
        and (o.organization_profile_id = public.current_profile_id() or public.is_admin())
    )
  );

-- ---- 9.3 helper-documents (strict) ----------------------------------------
-- Path convention: `helpers/{helper_profile_id}/documents/{document_id}.{ext}`
create policy "helper_documents_select_owner"
  on storage.objects for select
  using (
    bucket_id = 'helper-documents'
    and split_part(name, '/', 2) = public.current_profile_id()::text
  );

create policy "helper_documents_select_shared_org"
  on storage.objects for select
  using (
    bucket_id = 'helper-documents'
    and exists (
      select 1
      from public.helper_documents d
      join public.application_document_shares s on s.document_id = d.id
      join public.applications                a on a.id = s.application_id
      join public.offers                      o on o.id = a.offer_id
      where d.storage_bucket = 'helper-documents'
        and d.storage_path   = storage.objects.name
        and s.revoked_at is null
        and o.organization_profile_id = public.current_profile_id()
    )
  );

create policy "helper_documents_select_admin"
  on storage.objects for select
  using (bucket_id = 'helper-documents' and public.is_admin());

create policy "helper_documents_write_owner"
  on storage.objects for insert
  with check (
    bucket_id = 'helper-documents'
    and split_part(name, '/', 2) = public.current_profile_id()::text
  );

create policy "helper_documents_delete_owner"
  on storage.objects for delete
  using (
    bucket_id = 'helper-documents'
    and (
      split_part(name, '/', 2) = public.current_profile_id()::text
      or public.is_admin()
    )
  );

-- =============================================================================
-- 10. REALTIME PUBLICATION
-- =============================================================================

do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'messages'
    ) then
      alter publication supabase_realtime add table public.messages;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'conversations'
    ) then
      alter publication supabase_realtime add table public.conversations;
    end if;

    if not exists (
      select 1 from pg_publication_tables
      where pubname = 'supabase_realtime'
        and schemaname = 'public'
        and tablename = 'notifications'
    ) then
      alter publication supabase_realtime add table public.notifications;
    end if;
  end if;
end;
$$;

-- =============================================================================
-- 11. GRANTS (Supabase exposes `public` schema via PostgREST automatically)
-- =============================================================================

grant usage on schema public to anon, authenticated, service_role;

-- Views need explicit select for the api roles
grant select on public.public_profiles_view             to anon, authenticated;
grant select on public.published_offers_view            to anon, authenticated;
grant select on public.organization_rating_summary_view to authenticated;
grant select on public.helper_rating_summary_view       to authenticated;

commit;

-- =============================================================================
-- End of schema.sql
-- =============================================================================

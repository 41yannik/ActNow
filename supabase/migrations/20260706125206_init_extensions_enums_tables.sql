set client_min_messages = warning;

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


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


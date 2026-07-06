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


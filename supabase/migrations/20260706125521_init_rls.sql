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


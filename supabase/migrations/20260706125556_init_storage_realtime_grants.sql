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


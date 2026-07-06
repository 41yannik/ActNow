-- =============================================================================
-- Harden function EXECUTE grants on Supabase Cloud.
--
-- Supabase's default privileges grant EXECUTE on new functions in `public`
-- to anon/authenticated/service_role. The original schema only revoked from
-- PUBLIC, so anon retained EXECUTE via the default grant. Per design, RPCs
-- are authenticated-only; trigger/internal functions are not client-callable.
-- =============================================================================

-- RPCs: authenticated only (grants already in place from init_views_rpcs)
revoke execute on function public.search_offers(text, timestamptz, timestamptz, public.offer_type, text[], int, int) from anon;
revoke execute on function public.publish_offer(uuid)                       from anon;
revoke execute on function public.accept_application(uuid)                  from anon;
revoke execute on function public.reject_application(uuid, text)            from anon;
revoke execute on function public.withdraw_application(uuid)                from anon;
revoke execute on function public.complete_application(uuid)                from anon;
revoke execute on function public.create_conversation_for_application(uuid) from anon;
revoke execute on function public.list_community_conversations(int, int)    from anon;
revoke execute on function public.get_community_summary()                   from anon;
revoke execute on function public.mark_conversation_read(uuid)              from anon;

-- Caller helpers: authenticated only
revoke execute on function public.is_admin()           from anon;
revoke execute on function public.current_profile_id() from anon;

-- Trigger / internal functions: not callable by API roles at all
revoke execute on function public.set_updated_at()                          from anon, authenticated;
revoke execute on function public.handle_new_auth_user()                    from anon, authenticated;
revoke execute on function public.tg_profiles_protect_columns()             from anon, authenticated;
revoke execute on function public.tg_offers_validate_status_change()        from anon, authenticated;
revoke execute on function public.tg_applications_validate_status_change()  from anon, authenticated;
revoke execute on function public.tg_applications_status_side_effects()     from anon, authenticated;
revoke execute on function public.tg_ratings_recompute()                    from anon, authenticated;
revoke execute on function public.tg_validate_document_share()              from anon, authenticated;
revoke execute on function public.tg_ensure_conversation_for_application()  from anon, authenticated;
revoke execute on function public.tg_validate_conversation_consistency()    from anon, authenticated;
revoke execute on function public.tg_messages_guard_update()                from anon, authenticated;
revoke execute on function public.tg_messages_after_insert_side_effects()   from anon, authenticated;
revoke execute on function public.recompute_offer_accepted_count(uuid)      from anon, authenticated;
revoke execute on function public.recompute_profile_rating(uuid)            from anon, authenticated;

-- Prevent future default grants to anon on functions created by postgres
alter default privileges for role postgres in schema public
  revoke execute on functions from anon;

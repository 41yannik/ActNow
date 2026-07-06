-- Trigger/internal functions retained the implicit PUBLIC execute grant
-- (the previous migration only revoked anon/authenticated). Trigger-returning
-- functions cannot be invoked via PostgREST anyway, but revoke strictly.

revoke execute on function public.set_updated_at()                          from public;
revoke execute on function public.handle_new_auth_user()                    from public;
revoke execute on function public.tg_profiles_protect_columns()             from public;
revoke execute on function public.tg_offers_validate_status_change()        from public;
revoke execute on function public.tg_applications_validate_status_change()  from public;
revoke execute on function public.tg_applications_status_side_effects()     from public;
revoke execute on function public.tg_ratings_recompute()                    from public;
revoke execute on function public.tg_validate_document_share()              from public;
revoke execute on function public.tg_ensure_conversation_for_application()  from public;
revoke execute on function public.tg_validate_conversation_consistency()    from public;
revoke execute on function public.tg_messages_guard_update()                from public;
revoke execute on function public.tg_messages_after_insert_side_effects()   from public;
revoke execute on function public.recompute_offer_accepted_count(uuid)      from public;
revoke execute on function public.recompute_profile_rating(uuid)            from public;

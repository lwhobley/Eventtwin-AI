-- Trigger functions run as their owner. API clients must not invoke them.
revoke execute on function public.handle_new_eventtwin_user()
  from public, anon, authenticated;
revoke execute on function public.rls_auto_enable()
  from public, anon, authenticated;

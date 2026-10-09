-- Run with a privileged SQL connection. Every fixture is rolled back.
begin;

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-000000000101', 'eventtwin-rls-a@example.invalid', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-000000000102', 'eventtwin-rls-b@example.invalid', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-000000000103', 'eventtwin-rls-viewer@example.invalid', 'authenticated', 'authenticated');

insert into public.organizations (id, name, created_by) values
  ('00000000-0000-4000-8000-000000000201', 'RLS fixture A', '00000000-0000-4000-8000-000000000101'),
  ('00000000-0000-4000-8000-000000000202', 'RLS fixture B', '00000000-0000-4000-8000-000000000102');

insert into public.organization_members (organization_id, user_id, role) values
  ('00000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000101', 'owner'),
  ('00000000-0000-4000-8000-000000000202', '00000000-0000-4000-8000-000000000102', 'owner'),
  ('00000000-0000-4000-8000-000000000201', '00000000-0000-4000-8000-000000000103', 'viewer');

insert into public.venues (id, organization_id, name) values
  ('00000000-0000-4000-8000-000000000301', '00000000-0000-4000-8000-000000000201', 'Venue A'),
  ('00000000-0000-4000-8000-000000000302', '00000000-0000-4000-8000-000000000202', 'Venue B');

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000101', true);

do $$
declare
  changed integer;
begin
  if (select count(*) from public.organizations) <> 1
    or (select count(*) from public.venues) <> 1 then
    raise exception 'Owner A can read another organization';
  end if;

  update public.venues set name = 'Blocked change'
    where id = '00000000-0000-4000-8000-000000000302';
  get diagnostics changed = row_count;
  if changed <> 0 then
    raise exception 'Owner A changed another organization venue';
  end if;

  begin
    insert into public.venues (organization_id, name)
      values ('00000000-0000-4000-8000-000000000202', 'Blocked insert');
    raise exception 'Owner A inserted into another organization';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000103', true);

do $$
declare
  changed integer;
begin
  if (select count(*) from public.organizations) <> 1
    or (select count(*) from public.venues) <> 1 then
    raise exception 'Viewer can read another organization';
  end if;

  update public.venues set name = 'Blocked viewer change'
    where id = '00000000-0000-4000-8000-000000000301';
  get diagnostics changed = row_count;
  if changed <> 0 then
    raise exception 'Viewer changed a venue';
  end if;

  begin
    insert into public.venues (organization_id, name)
      values ('00000000-0000-4000-8000-000000000201', 'Blocked viewer insert');
    raise exception 'Viewer inserted a venue';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

rollback;

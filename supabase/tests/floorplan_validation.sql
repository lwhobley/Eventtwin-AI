-- Run with a privileged SQL connection. Every fixture is rolled back.
begin;

insert into auth.users (id, email, aud, role) values
  ('00000000-0000-4000-8000-000000000401', 'eventtwin-layout-test@example.invalid', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-000000000406', 'eventtwin-layout-other@example.invalid', 'authenticated', 'authenticated'),
  ('00000000-0000-4000-8000-000000000411', 'eventtwin-layout-viewer@example.invalid', 'authenticated', 'authenticated');
insert into public.organizations (id, name, created_by) values
  ('00000000-0000-4000-8000-000000000402', 'Layout test', '00000000-0000-4000-8000-000000000401'),
  ('00000000-0000-4000-8000-000000000407', 'Other layout test', '00000000-0000-4000-8000-000000000406');
insert into public.organization_members (organization_id, user_id, role) values
  ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000401', 'owner'),
  ('00000000-0000-4000-8000-000000000407', '00000000-0000-4000-8000-000000000406', 'owner'),
  ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000411', 'viewer');
insert into public.venues (id, organization_id, name) values
  ('00000000-0000-4000-8000-000000000403', '00000000-0000-4000-8000-000000000402', 'Test venue'),
  ('00000000-0000-4000-8000-000000000408', '00000000-0000-4000-8000-000000000407', 'Other venue');
insert into public.spaces (id, organization_id, venue_id, name, width_m, depth_m, measurements_verified) values
  ('00000000-0000-4000-8000-000000000404', '00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000403', 'Test room', 24, 18, true),
  ('00000000-0000-4000-8000-000000000409', '00000000-0000-4000-8000-000000000407', '00000000-0000-4000-8000-000000000408', 'Other room', 24, 18, true);
insert into public.events (id, organization_id, space_id, name, guest_count, requirements_confirmed) values
  ('00000000-0000-4000-8000-000000000405', '00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000404', 'Test event', 20, true),
  ('00000000-0000-4000-8000-000000000410', '00000000-0000-4000-8000-000000000407', '00000000-0000-4000-8000-000000000409', 'Other event', 20, true);

set local role authenticated;
select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000401', true);

insert into public.floorplans (organization_id, event_id, name, version, objects, validation) values
  ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000405', 'Valid draft', 1,
   '[{"type":"round_table","x_m":3,"y_m":3},{"type":"round_table","x_m":7,"y_m":3}]',
   '{"status":"approved"}');

do $$
begin
  if not exists (
    select 1 from public.floorplans
    where name = 'Valid draft'
      and validation ->> 'status' = 'draft_geometry_checked'
      and validation ->> 'seat_capacity' = '20'
      and created_by = auth.uid()
      and approved_at is null
  ) then
    raise exception 'Server did not set draft validation and author';
  end if;

  begin
    insert into public.floorplans (organization_id, event_id, name, version, objects) values
      ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000405', 'Collision', 1,
       '[{"type":"round_table","x_m":3,"y_m":3},{"type":"round_table","x_m":4,"y_m":3}]');
    raise exception 'Accepted colliding tables';
  exception when raise_exception then
    if sqlerrm <> 'Tables 1 and 2 overlap their clearance zones' then raise; end if;
  end;

  begin
    insert into public.floorplans (organization_id, event_id, name, version, objects) values
      ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000405', 'Out of bounds', 1,
       '[{"type":"round_table","x_m":1,"y_m":3},{"type":"round_table","x_m":7,"y_m":3}]');
    raise exception 'Accepted table outside room';
  exception when raise_exception then
    if sqlerrm <> 'Table 1 exceeds room boundaries or clearance' then raise; end if;
  end;

  begin
    insert into public.floorplans (organization_id, event_id, name, version, objects) values
      ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000405', 'Too few tables', 1,
       '[{"type":"round_table","x_m":3,"y_m":3}]');
    raise exception 'Accepted insufficient seating';
  exception when raise_exception then
    if sqlerrm not like 'The draft must contain one round table%' then raise; end if;
  end;

  update public.spaces set measurements_verified = false
    where id = '00000000-0000-4000-8000-000000000404';
  begin
    insert into public.floorplans (organization_id, event_id, name, version, objects) values
      ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000405', 'Unverified room', 1,
       '[{"type":"round_table","x_m":3,"y_m":3},{"type":"round_table","x_m":7,"y_m":3}]');
    raise exception 'Accepted unverified room';
  exception when raise_exception then
    if sqlerrm <> 'Verify room measurements and confirm event requirements first' then raise; end if;
  end;
  update public.spaces set measurements_verified = true
    where id = '00000000-0000-4000-8000-000000000404';

  update public.events set requirements_confirmed = false
    where id = '00000000-0000-4000-8000-000000000405';
  begin
    insert into public.floorplans (organization_id, event_id, name, version, objects) values
      ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000405', 'Unconfirmed event', 1,
       '[{"type":"round_table","x_m":3,"y_m":3},{"type":"round_table","x_m":7,"y_m":3}]');
    raise exception 'Accepted unconfirmed event';
  exception when raise_exception then
    if sqlerrm <> 'Verify room measurements and confirm event requirements first' then raise; end if;
  end;
  update public.events set requirements_confirmed = true
    where id = '00000000-0000-4000-8000-000000000405';

  begin
    update public.floorplans set name = 'Changed' where name = 'Valid draft';
    raise exception 'Allowed an old version to be edited';
  exception when insufficient_privilege then
    null;
  end;

  begin
    insert into public.floorplans (organization_id, event_id, name, version, objects) values
      ('00000000-0000-4000-8000-000000000407', '00000000-0000-4000-8000-000000000410', 'Cross-tenant insert', 1,
       '[{"type":"round_table","x_m":3,"y_m":3},{"type":"round_table","x_m":7,"y_m":3}]');
    raise exception 'Allowed a cross-tenant draft';
  exception when raise_exception then
    if sqlerrm <> 'Event and room are not available in this organization' then raise; end if;
  end;
end;
$$;

select set_config('request.jwt.claim.sub', '00000000-0000-4000-8000-000000000411', true);
do $$
begin
  if (select count(*) from public.floorplans) <> 1 then
    raise exception 'Viewer did not see their organization draft';
  end if;
  begin
    insert into public.floorplans (organization_id, event_id, name, version, objects) values
      ('00000000-0000-4000-8000-000000000402', '00000000-0000-4000-8000-000000000405', 'Viewer insert', 1,
       '[{"type":"round_table","x_m":3,"y_m":3},{"type":"round_table","x_m":7,"y_m":3}]');
    raise exception 'Allowed a viewer to create a draft';
  exception when insufficient_privilege then
    null;
  end;
end;
$$;

rollback;

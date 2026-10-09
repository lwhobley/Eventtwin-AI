-- The first cloud layout format supports round banquet tables only.
-- Exits and fixed architectural features are not modeled, so these remain drafts.
create function public.validate_floorplan_draft()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  room_width numeric;
  room_depth numeric;
  room_verified boolean;
  requirements_confirmed boolean;
  guests integer;
  table_count integer;
  table_index integer;
  other_index integer;
  table_object jsonb;
  other_object jsonb;
  x numeric;
  y numeric;
  other_x numeric;
  other_y numeric;
begin
  select s.width_m, s.depth_m, s.measurements_verified,
         e.requirements_confirmed, e.guest_count
    into room_width, room_depth, room_verified, requirements_confirmed, guests
    from public.events e
    join public.spaces s on s.id = e.space_id
      and s.organization_id = e.organization_id
    where e.id = new.event_id and e.organization_id = new.organization_id;

  if not found then
    raise exception 'Event and room are not available in this organization';
  end if;
  if not room_verified or not requirements_confirmed then
    raise exception 'Verify room measurements and confirm event requirements first';
  end if;

  table_count := jsonb_array_length(new.objects);
  if table_count < 1 or table_count > 500
     or table_count <> ceil(guests / 10.0) then
    raise exception 'The draft must contain one round table per ten guests (maximum 500 tables)';
  end if;

  for table_index in 0..table_count - 1 loop
    table_object := new.objects -> table_index;
    if jsonb_typeof(table_object) is distinct from 'object'
       or table_object ->> 'type' is distinct from 'round_table'
       or jsonb_typeof(table_object -> 'x_m') is distinct from 'number'
       or jsonb_typeof(table_object -> 'y_m') is distinct from 'number' then
      raise exception 'Each table needs a type and measured x_m/y_m coordinates';
    end if;

    x := (table_object ->> 'x_m')::numeric;
    y := (table_object ->> 'y_m')::numeric;
    if x < 1.8 or y < 1.8
       or x > room_width - 1.8 or y > room_depth - 1.8 then
      raise exception 'Table % exceeds room boundaries or clearance', table_index + 1;
    end if;

    for other_index in 0..table_index - 1 loop
      other_object := new.objects -> other_index;
      other_x := (other_object ->> 'x_m')::numeric;
      other_y := (other_object ->> 'y_m')::numeric;
      if power(x - other_x, 2) + power(y - other_y, 2) < power(3.6, 2) then
        raise exception 'Tables % and % overlap their clearance zones',
          other_index + 1, table_index + 1;
      end if;
    end loop;
  end loop;

  new.created_by := auth.uid();
  if new.created_by is null then
    raise exception 'Authentication is required';
  end if;
  new.validation := jsonb_build_object(
    'status', 'draft_geometry_checked',
    'ruleset', 'round_tables_v1',
    'table_count', table_count,
    'seat_capacity', table_count * 10,
    'room_width_m', room_width,
    'room_depth_m', room_depth
  );
  return new;
end;
$$;

revoke all on function public.validate_floorplan_draft()
  from public, anon, authenticated;

create trigger validate_floorplan_draft_before_insert
  before insert on public.floorplans
  for each row execute function public.validate_floorplan_draft();

-- Editing creates a new version. Earlier versions remain immutable.
revoke update, delete on public.floorplans from authenticated;

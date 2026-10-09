create table public.profiles (
  user_id uuid primary key references auth.users (id) on delete cascade,
  full_name text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.organizations (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 120),
  created_by uuid not null references auth.users (id),
  created_at timestamptz not null default now()
);

create table public.organization_members (
  organization_id uuid not null references public.organizations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null check (role in ('owner', 'administrator', 'event_manager', 'designer', 'operations_manager', 'viewer')),
  created_at timestamptz not null default now(),
  primary key (organization_id, user_id)
);

create index organization_members_user_idx on public.organization_members (user_id, organization_id);

create table public.venues (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  name text not null check (length(trim(name)) between 1 and 160),
  created_at timestamptz not null default now(),
  unique (id, organization_id)
);

create table public.spaces (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  venue_id uuid not null,
  name text not null check (length(trim(name)) between 1 and 160),
  width_m numeric not null check (width_m > 0),
  depth_m numeric not null check (depth_m > 0),
  measurements_verified boolean not null default false,
  created_at timestamptz not null default now(),
  unique (id, organization_id),
  foreign key (venue_id, organization_id)
    references public.venues (id, organization_id) on delete cascade
);

create index venues_organization_idx on public.venues (organization_id, created_at);
create index spaces_organization_venue_idx on public.spaces (organization_id, venue_id, created_at);

create table public.events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  space_id uuid not null,
  name text not null check (length(trim(name)) between 1 and 200),
  guest_count integer not null check (guest_count between 1 and 100000),
  source_text text not null default '',
  requirements_confirmed boolean not null default false,
  created_at timestamptz not null default now(),
  unique (id, organization_id),
  foreign key (space_id, organization_id)
    references public.spaces (id, organization_id) on delete restrict
);

create index events_organization_idx on public.events (organization_id, created_at desc);

create table public.floorplans (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete cascade,
  event_id uuid not null,
  name text not null check (length(trim(name)) between 1 and 120),
  version integer not null check (version > 0),
  objects jsonb not null default '[]'::jsonb check (jsonb_typeof(objects) = 'array'),
  validation jsonb not null default '{}'::jsonb,
  approved_at timestamptz check (approved_at is null),
  created_by uuid not null default auth.uid() references auth.users (id),
  created_at timestamptz not null default now(),
  unique (id, organization_id),
  unique (event_id, name, version),
  foreign key (event_id, organization_id)
    references public.events (id, organization_id) on delete cascade
);

create index floorplans_organization_event_idx on public.floorplans (organization_id, event_id, created_at desc);

create or replace function public.is_organization_member(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = target_organization_id
      and m.user_id = (select auth.uid())
  );
$$;

create or replace function public.can_edit_organization(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = target_organization_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner', 'administrator', 'event_manager', 'designer', 'operations_manager')
  );
$$;

create or replace function public.can_admin_organization(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = target_organization_id
      and m.user_id = (select auth.uid())
      and m.role in ('owner', 'administrator')
  );
$$;

create or replace function public.is_organization_owner(target_organization_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.organization_members m
    where m.organization_id = target_organization_id
      and m.user_id = (select auth.uid())
      and m.role = 'owner'
  );
$$;

create or replace function public.create_organization(organization_name text)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  new_organization_id uuid;
  clean_name text := trim(organization_name);
begin
  if auth.uid() is null then
    raise exception 'Authentication is required';
  end if;
  if clean_name is null or length(clean_name) = 0 or length(clean_name) > 120 then
    raise exception 'Organization name must contain 1 to 120 characters';
  end if;

  insert into public.organizations (name, created_by)
  values (clean_name, auth.uid())
  returning id into new_organization_id;

  insert into public.organization_members (organization_id, user_id, role)
  values (new_organization_id, auth.uid(), 'owner');

  return new_organization_id;
end;
$$;

create or replace function public.handle_new_eventtwin_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (user_id, full_name)
  values (new.id, nullif(trim(new.raw_user_meta_data ->> 'full_name'), ''))
  on conflict (user_id) do nothing;
  return new;
end;
$$;

create trigger on_auth_user_created_eventtwin
  after insert on auth.users
  for each row execute procedure public.handle_new_eventtwin_user();

revoke all on function public.is_organization_member(uuid) from public, anon;
revoke all on function public.can_edit_organization(uuid) from public, anon;
revoke all on function public.can_admin_organization(uuid) from public, anon;
revoke all on function public.is_organization_owner(uuid) from public, anon;
revoke all on function public.create_organization(text) from public, anon;
grant execute on function public.is_organization_member(uuid) to authenticated;
grant execute on function public.can_edit_organization(uuid) to authenticated;
grant execute on function public.can_admin_organization(uuid) to authenticated;
grant execute on function public.is_organization_owner(uuid) to authenticated;
grant execute on function public.create_organization(text) to authenticated;

alter table public.profiles enable row level security;
alter table public.organizations enable row level security;
alter table public.organization_members enable row level security;
alter table public.venues enable row level security;
alter table public.spaces enable row level security;
alter table public.events enable row level security;
alter table public.floorplans enable row level security;

grant select, update on public.profiles to authenticated;
grant select, update on public.organizations to authenticated;
grant select, insert, update, delete on public.organization_members to authenticated;
grant select, insert, update, delete on public.venues, public.spaces, public.events, public.floorplans to authenticated;

create policy "users read own profile" on public.profiles
  for select to authenticated using (user_id = (select auth.uid()));
create policy "users update own profile" on public.profiles
  for update to authenticated using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy "members read organization" on public.organizations
  for select to authenticated using (public.is_organization_member(id));
create policy "admins update organization" on public.organizations
  for update to authenticated using (public.can_admin_organization(id))
  with check (public.can_admin_organization(id));

create policy "members read membership list" on public.organization_members
  for select to authenticated using (
    user_id = (select auth.uid()) or public.is_organization_member(organization_id)
  );
create policy "admins add members" on public.organization_members
  for insert to authenticated with check (
    public.is_organization_owner(organization_id)
    or (public.can_admin_organization(organization_id) and role not in ('owner', 'administrator'))
  );
create policy "admins update members" on public.organization_members
  for update to authenticated
  using (
    public.is_organization_owner(organization_id)
    or (public.can_admin_organization(organization_id) and role not in ('owner', 'administrator'))
  )
  with check (
    public.is_organization_owner(organization_id)
    or (public.can_admin_organization(organization_id) and role not in ('owner', 'administrator'))
  );
create policy "admins remove members" on public.organization_members
  for delete to authenticated using (
    user_id <> (select auth.uid())
    and role <> 'owner'
    and (
      public.is_organization_owner(organization_id)
      or (public.can_admin_organization(organization_id) and role <> 'administrator')
    )
  );

create policy "members read venues" on public.venues
  for select to authenticated using (public.is_organization_member(organization_id));
create policy "editors manage venues" on public.venues
  for all to authenticated using (public.can_edit_organization(organization_id))
  with check (public.can_edit_organization(organization_id));

create policy "members read spaces" on public.spaces
  for select to authenticated using (public.is_organization_member(organization_id));
create policy "editors manage spaces" on public.spaces
  for all to authenticated using (public.can_edit_organization(organization_id))
  with check (public.can_edit_organization(organization_id));

create policy "members read events" on public.events
  for select to authenticated using (public.is_organization_member(organization_id));
create policy "editors manage events" on public.events
  for all to authenticated using (public.can_edit_organization(organization_id))
  with check (public.can_edit_organization(organization_id));

create policy "members read floorplans" on public.floorplans
  for select to authenticated using (public.is_organization_member(organization_id));
create policy "editors manage floorplans" on public.floorplans
  for all to authenticated using (public.can_edit_organization(organization_id))
  with check (public.can_edit_organization(organization_id));

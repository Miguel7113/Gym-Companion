-- Gym notices: Home + Notices screens (not social feed). Soft-delete via deleted_at.
--
-- Self-contained: recreates JWT helpers if 008 was never applied on this project.
-- get_my_gym_id() returns uuid; gym FKs are text — always compare with ::text casts.

create or replace function public.get_my_gym_id()
returns uuid
language sql stable security definer
as $$
  select nullif(
    (auth.jwt() -> 'user_metadata' ->> 'gym_id'),
    ''
  )::uuid;
$$;

create or replace function public.get_my_member_id()
returns uuid
language sql stable security definer
as $$
  select nullif(
    (auth.jwt() -> 'user_metadata' ->> 'member_id'),
    ''
  )::uuid;
$$;

create or replace function public.get_my_role()
returns text
language sql stable security definer
as $$
  select nullif(
    (auth.jwt() -> 'user_metadata' ->> 'role'),
    ''
  )::text;
$$;

create or replace function public.is_staff()
returns boolean
language sql stable security definer
as $$
  select coalesce(
    (auth.jwt() -> 'user_metadata' ->> 'role') in ('coach', 'admin'),
    false
  );
$$;

create table if not exists public.gym_notices (
  id text primary key,
  gym_id text not null references public.gyms(id) on delete cascade,
  author_user_id text references public.users(id) on delete set null,
  author_staff_id text references public.gym_staff(id) on delete set null,
  title text not null,
  body text not null,
  tag text not null,
  is_pinned boolean not null default false,
  published_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

create index if not exists gym_notices_gym_id_idx on public.gym_notices (gym_id);
create index if not exists gym_notices_list_idx
  on public.gym_notices (gym_id, deleted_at, is_pinned, published_at);

alter table public.gym_notices enable row level security;

drop policy if exists "gym_notices: members read own gym" on public.gym_notices;
drop policy if exists "gym_notices: staff insert" on public.gym_notices;
drop policy if exists "gym_notices: staff update" on public.gym_notices;

create policy "gym_notices: members read own gym"
  on public.gym_notices for select
  using (
    gym_id::text = public.get_my_gym_id()::text
    and deleted_at is null
  );

create policy "gym_notices: staff insert"
  on public.gym_notices for insert
  with check (
    gym_id::text = public.get_my_gym_id()::text
    and public.is_staff()
  );

create policy "gym_notices: staff update"
  on public.gym_notices for update
  using (
    gym_id::text = public.get_my_gym_id()::text
    and public.is_staff()
  );

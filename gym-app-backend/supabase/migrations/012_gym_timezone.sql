-- Used for server-authoritative local-calendar streaks.
alter table public.gyms
  add column if not exists timezone text not null default 'UTC';

-- Keep Supabase deployments in sync with the Prisma routine-session link.
alter table public.workout_sessions
  add column if not exists template_id text;

create index if not exists workout_sessions_template_id_idx
  on public.workout_sessions (template_id);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'workout_sessions_template_id_fkey'
  ) then
    alter table public.workout_sessions
      add constraint workout_sessions_template_id_fkey
      foreign key (template_id) references public.workout_templates(id)
      on delete set null on update cascade;
  end if;
end $$;

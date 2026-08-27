-- ═════════════════════════════════════════════════════════════════════════════
-- TRIGGERS & FUNCTIONS
-- ═════════════════════════════════════════════════════════════════════════════

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. Link auth user to gym_member on first claim
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.sync_member_to_auth()
returns trigger as $$
begin
  if new.auth_user_id is not null and old.auth_user_id is null then
    update auth.users
    set raw_user_meta_data = raw_user_meta_data || jsonb_build_object(
      'gym_id', new.gym_id,
      'member_id', new.id,
      'role', new.role
    )
    where id = new.auth_user_id;
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_member_claimed
  after update on public.gym_members
  for each row
  when (new.auth_user_id is distinct from old.auth_user_id)
  execute function public.sync_member_to_auth();

-- ─────────────────────────────────────────────────────────────────────────────
-- 2. Auto-post PR to feed when personal record is set
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.handle_pr_to_feed()
returns trigger as $$
declare
  v_member_name text;
  v_exercise_name text;
  v_content text;
  v_workout_id uuid;
begin
  select full_name into v_member_name
  from public.gym_members where id = new.member_id;

  select name into v_exercise_name
  from public.exercises where id = new.exercise_id;

  select id into v_workout_id
  from public.workout_sessions
  where member_id = new.member_id
  order by started_at desc
  limit 1;

  v_content := v_member_name || ' hit a new PR on ' || v_exercise_name || 
               ': ' || new.value || ' ' || new.unit || '!';

  insert into public.feed_posts (
    gym_id, author_id, post_type, content,
    related_workout_id, related_pr_id
  ) values (
    new.gym_id, new.member_id, 'pr', v_content,
    v_workout_id, new.id
  );

  return new;
end;
$$ language plpgsql security definer;

create trigger on_pr_created
  after insert on public.personal_records
  for each row
  execute function public.handle_pr_to_feed();

-- ─────────────────────────────────────────────────────────────────────────────
-- 3. Auto-post workout completion to feed
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.handle_workout_complete_to_feed()
returns trigger as $$
declare
  v_member_name text;
  v_content text;
  v_exercise_count int;
begin
  if new.ended_at is not null and old.ended_at is null then
    select full_name into v_member_name
    from public.gym_members where id = new.member_id;

    select count(distinct exercise_id) into v_exercise_count
    from public.workout_sets where session_id = new.id;

    v_content := v_member_name || ' completed a workout with ' || 
                 v_exercise_count || ' exercises.';

    insert into public.feed_posts (
      gym_id, author_id, post_type, content, related_workout_id
    ) values (
      new.gym_id, new.member_id, 'workout_complete', v_content, new.id
    );
  end if;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_workout_completed
  after update on public.workout_sessions
  for each row
  when (new.ended_at is not null and old.ended_at is null)
  execute function public.handle_workout_complete_to_feed();

-- ─────────────────────────────────────────────────────────────────────────────
-- 4. Increment/decrement like counts
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.update_likes_count()
returns trigger as $$
begin
  if tg_op = 'INSERT' then
    update public.feed_posts set likes_count = likes_count + 1 where id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.feed_posts set likes_count = likes_count - 1 where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$ language plpgsql security definer;

create trigger on_like_change
  after insert or delete on public.post_likes
  for each row
  execute function public.update_likes_count();

-- ─────────────────────────────────────────────────────────────────────────────
-- 5. Increment/decrement comment counts
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.update_comments_count()
returns trigger as $$
begin
  if tg_op = 'INSERT' then
    update public.feed_posts set comments_count = comments_count + 1 where id = new.post_id;
    return new;
  elsif tg_op = 'DELETE' then
    update public.feed_posts set comments_count = comments_count - 1 where id = old.post_id;
    return old;
  end if;
  return null;
end;
$$ language plpgsql security definer;

create trigger on_comment_change
  after insert or delete on public.post_comments
  for each row
  execute function public.update_comments_count();

-- ─────────────────────────────────────────────────────────────────────────────
-- 6. Update member last_active_at
-- ─────────────────────────────────────────────────────────────────────────────

create or replace function public.update_member_last_active()
returns trigger as $$
begin
  update public.gym_members
  set last_active_at = now()
  where id = new.member_id;
  return new;
end;
$$ language plpgsql security definer;

create trigger on_session_created
  after insert on public.workout_sessions
  for each row
  execute function public.update_member_last_active();

# Staff Portal Setup

Use this when testing the first admin/staff login for `tether-web`.

## What the portal expects

- A Supabase Auth user exists for the staff email
- A matching `gym_staff` row exists in the database
- The `gym_staff.email` matches the Supabase user email
- The `gym_staff.gym_id` points at the gym the staff member manages

`auth_provider_id` can be left empty at first. On successful portal login, the backend will attach it automatically if the email matches.

## Fastest setup path

### 1. Create the auth user in Supabase

In Supabase Dashboard:

- Go to `Authentication` -> `Users`
- Create a user with the staff email
- Set a password
- Copy the created user id if you want to link it immediately

### 2. Create the `gym_staff` row

In the SQL editor, run:

```sql
insert into public.gym_staff (
  id,
  gym_id,
  email,
  role,
  auth_provider_id
) values (
  gen_random_uuid()::text,
  '<gym_id_here>',
  'staff@example.com',
  'admin',
  null
);
```

If you want to pre-link the auth account immediately, replace `null` with the Supabase user id:

```sql
insert into public.gym_staff (
  id,
  gym_id,
  email,
  role,
  auth_provider_id
) values (
  gen_random_uuid()::text,
  '<gym_id_here>',
  'staff@example.com',
  'admin',
  '<supabase_auth_user_id>'
);
```

## Roles

- `admin` -> website portal user
- `coach` -> can still exist in `gym_staff` for notice/certification behavior

For the first portal account, use `admin`.

## Login test

1. Start backend on `http://localhost:3001` or set `PORT=3001`
2. In `tether-web/.env.local`, set `NEXT_PUBLIC_API_URL=http://localhost:3001`
3. Start `tether-web`
4. Open `/login`
5. Sign in with the staff email and password from Supabase Auth

If login succeeds, the backend returns:

- `accessToken`
- `refreshToken`
- `staff.id`
- `staff.gymId`
- `staff.email`
- `staff.role`

## Common failure cases

### `Not a registered staff member`

The Supabase auth user exists, but there is no matching `gym_staff.email`.

### Login works in Supabase but portal still fails

Usually one of:

- wrong `gym_id` on `gym_staff`
- backend `DATABASE_URL` points at the wrong database
- auth user was created in a different Supabase project than the DB row

### Dashboard loads but has no useful data

The staff account is valid, but the target gym has no members / roster rows / activity yet.

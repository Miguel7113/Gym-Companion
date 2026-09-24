'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import {
  ACCESS_TOKEN_COOKIE,
  EMAIL_COOKIE,
  GYM_ID_COOKIE,
} from '@/lib/auth';

export async function logoutStaff() {
  const store = await cookies();
  store.delete(ACCESS_TOKEN_COOKIE);
  store.delete(GYM_ID_COOKIE);
  store.delete(EMAIL_COOKIE);
  redirect('/login');
}

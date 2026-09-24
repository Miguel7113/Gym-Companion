'use server';

import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';
import {
  ACCESS_TOKEN_COOKIE,
  EMAIL_COOKIE,
  GYM_ID_COOKIE,
} from '@/lib/auth';
import { serverApiFetch } from '@/lib/server-api';

type StaffLoginResponse = {
  accessToken: string;
  staff: {
    gymId: string;
    email: string;
  };
};

export async function loginStaff(formData: FormData) {
  const email = String(formData.get('email') ?? '').trim();
  const password = String(formData.get('password') ?? '').trim();

  if (!email || !password) {
    redirect('/login?error=Email%20and%20password%20are%20required.');
  }

  const response = await serverApiFetch('/auth/staff/login', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password }),
  });

  if (!response.ok) {
    redirect('/login?error=Login%20failed.%20Check%20the%20staff%20account%20and%20password.');
  }

  const data = (await response.json()) as StaffLoginResponse;
  const store = await cookies();
  const secure =
    process.env.COOKIE_SECURE === 'true' ||
    process.env.NODE_ENV === 'production';
  const cookieOptions = {
    httpOnly: true,
    sameSite: 'lax' as const,
    path: '/',
    secure,
  };
  store.set(ACCESS_TOKEN_COOKIE, data.accessToken, cookieOptions);
  store.set(GYM_ID_COOKIE, data.staff.gymId, cookieOptions);
  store.set(EMAIL_COOKIE, data.staff.email, cookieOptions);

  redirect('/dashboard');
}

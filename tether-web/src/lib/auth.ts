import { cookies } from 'next/headers';
import { redirect } from 'next/navigation';

export type StaffSession = {
  accessToken: string;
  gymId: string;
  email: string;
};

const ACCESS_TOKEN_COOKIE = 'tether_staff_access_token';
const GYM_ID_COOKIE = 'tether_staff_gym_id';
const EMAIL_COOKIE = 'tether_staff_email';

export async function getStaffSession(): Promise<StaffSession | null> {
  const store = await cookies();
  const accessToken = store.get(ACCESS_TOKEN_COOKIE)?.value;
  const gymId = store.get(GYM_ID_COOKIE)?.value;
  const email = store.get(EMAIL_COOKIE)?.value;

  if (!accessToken || !gymId || !email) return null;

  return { accessToken, gymId, email };
}

export async function requireStaffSession(): Promise<StaffSession> {
  const session = await getStaffSession();
  if (!session) redirect('/login');
  return session;
}

export { ACCESS_TOKEN_COOKIE, EMAIL_COOKIE, GYM_ID_COOKIE };

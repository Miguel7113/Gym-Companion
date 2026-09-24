'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { requireStaffSession } from '@/lib/auth';
import { serverApiFetch } from '@/lib/server-api';
import {
  isValidEmail,
  isValidHexColor,
  isValidHttpUrl,
  isValidTimezone,
} from '@/lib/validation';

async function readError(response: Response, fallback: string) {
  const text = await response.text();
  return text || fallback;
}

export async function updateGymSettings(formData: FormData) {
  const session = await requireStaffSession();

  const body = {
    name: String(formData.get('name') ?? '').trim(),
    logoUrl: String(formData.get('logoUrl') ?? '').trim(),
    primaryColor: String(formData.get('primaryColor') ?? '').trim(),
    timezone: String(formData.get('timezone') ?? '').trim(),
    contactEmail: String(formData.get('contactEmail') ?? '').trim(),
    subscriptionTier: String(formData.get('subscriptionTier') ?? '').trim(),
  };

  if (!body.name || !body.timezone || !body.subscriptionTier) {
    redirect('/dashboard/settings?error=Name,%20timezone,%20and%20subscription%20tier%20are%20required.');
  }
  if (!isValidTimezone(body.timezone)) {
    redirect('/dashboard/settings?error=Enter%20a%20valid%20IANA%20timezone.');
  }
  if (body.primaryColor && !isValidHexColor(body.primaryColor)) {
    redirect('/dashboard/settings?error=Primary%20color%20must%20be%20a%20hex%20color%20like%20%23C3F400.');
  }
  if (body.logoUrl && !isValidHttpUrl(body.logoUrl)) {
    redirect('/dashboard/settings?error=Logo%20URL%20must%20start%20with%20http%20or%20https.');
  }
  if (body.contactEmail && !isValidEmail(body.contactEmail)) {
    redirect('/dashboard/settings?error=Contact%20email%20must%20be%20valid.');
  }

  const response = await serverApiFetch(`/gyms/${session.gymId}/settings`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
    token: session.accessToken,
  });

  if (!response.ok) {
    redirect(
      `/dashboard/settings?error=${encodeURIComponent(
        await readError(response, 'Failed to update settings.'),
      )}`,
    );
  }

  revalidatePath('/dashboard/settings');
  redirect('/dashboard/settings?message=Settings%20updated');
}

export async function inviteStaff(formData: FormData) {
  const session = await requireStaffSession();
  const email = String(formData.get('email') ?? '').trim().toLowerCase();
  const password = String(formData.get('password') ?? '').trim();
  const role = String(formData.get('role') ?? 'admin').trim();

  if (!email || !password) {
    redirect('/dashboard/settings?error=Staff%20email%20and%20password%20are%20required.');
  }
  if (!isValidEmail(email)) {
    redirect('/dashboard/settings?error=Enter%20a%20valid%20staff%20email.');
  }
  if (password.length < 6) {
    redirect('/dashboard/settings?error=Staff%20password%20must%20be%20at%20least%206%20characters.');
  }
  if (!['admin', 'coach'].includes(role)) {
    redirect('/dashboard/settings?error=Choose%20a%20valid%20staff%20role.');
  }

  const response = await serverApiFetch('/auth/staff/invite', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, role }),
    token: session.accessToken,
  });

  if (!response.ok) {
    redirect(
      `/dashboard/settings?error=${encodeURIComponent(
        await readError(response, 'Failed to invite staff member.'),
      )}`,
    );
  }

  revalidatePath('/dashboard/settings');
  redirect('/dashboard/settings?message=Staff%20account%20created');
}

export async function updateStaffRole(formData: FormData) {
  const session = await requireStaffSession();
  const staffId = String(formData.get('staffId') ?? '').trim();
  const role = String(formData.get('role') ?? '').trim();

  if (!staffId || !['admin', 'coach'].includes(role)) {
    redirect('/dashboard/settings?error=Choose%20a%20valid%20staff%20role.');
  }

  const response = await serverApiFetch(`/auth/staff/${staffId}`, {
    method: 'PATCH',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ role }),
    token: session.accessToken,
  });

  if (!response.ok) {
    redirect(
      `/dashboard/settings?error=${encodeURIComponent(
        await readError(response, 'Failed to update staff role.'),
      )}`,
    );
  }

  revalidatePath('/dashboard/settings');
  redirect('/dashboard/settings?message=Staff%20role%20updated');
}

'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { requireStaffSession } from '@/lib/auth';
import { serverApiFetch } from '@/lib/server-api';
import { isLikelyPhone, isValidEmail } from '@/lib/validation';

export async function updateMember(formData: FormData) {
  const session = await requireStaffSession();
  const memberId = String(formData.get('memberId') ?? '').trim();

  const body = {
    displayName: String(formData.get('displayName') ?? '').trim(),
    email: String(formData.get('email') ?? '').trim(),
    phone: String(formData.get('phone') ?? '').trim(),
    subscriptionTier: String(formData.get('subscriptionTier') ?? '').trim(),
  };

  if (!memberId || !body.subscriptionTier) {
    redirect('/dashboard/members?error=Missing%20member%20id%20or%20subscription%20tier.');
  }
  if (body.email && !isValidEmail(body.email)) {
    redirect(`/dashboard/members/${memberId}?error=Enter%20a%20valid%20email%20address.`);
  }
  if (body.phone && !isLikelyPhone(body.phone)) {
    redirect(`/dashboard/members/${memberId}?error=Enter%20a%20valid%20phone%20number.`);
  }

  const response = await serverApiFetch(`/staff/members/${memberId}`, {
    method: 'PATCH',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
    token: session.accessToken,
  });

  if (!response.ok) {
    const text = await response.text();
    redirect(
      `/dashboard/members/${memberId}?error=${encodeURIComponent(
        text || 'Failed to update member.',
      )}`,
    );
  }

  revalidatePath(`/dashboard/members/${memberId}`);
  revalidatePath('/dashboard/members');
  redirect(`/dashboard/members/${memberId}?message=Member%20updated`);
}

export async function sendPasswordReset(formData: FormData) {
  const session = await requireStaffSession();
  const memberId = String(formData.get('memberId') ?? '').trim();

  if (!memberId) {
    redirect('/dashboard/members?error=Missing%20member%20id.');
  }

  const response = await serverApiFetch(
    `/auth/staff/members/${memberId}/reset-password`,
    {
      method: 'POST',
      token: session.accessToken,
    },
  );

  if (!response.ok) {
    const text = await response.text();
    redirect(
      `/dashboard/members/${memberId}?error=${encodeURIComponent(
        text || 'Failed to send password reset.',
      )}`,
    );
  }

  redirect(`/dashboard/members/${memberId}?message=Password%20reset%20email%20sent`);
}

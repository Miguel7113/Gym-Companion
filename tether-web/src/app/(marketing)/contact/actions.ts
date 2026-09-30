'use server';

import { serverApiFetch } from '@/lib/server-api';
import { isLikelyPhone, isValidEmail } from '@/lib/validation';

export type LeadFormState = {
  status: 'idle' | 'success' | 'error';
  message?: string;
};

const MEMBER_BANDS = new Set(['UNDER_100', '100_300', 'OVER_300']);

export async function submitLead(_prev: LeadFormState, formData: FormData): Promise<LeadFormState> {
  const field = (name: string) => String(formData.get(name) ?? '').trim();

  const gymName = field('gymName');
  const contactName = field('contactName');
  const email = field('email');
  const phone = field('phone');
  const city = field('city');
  const memberCount = field('memberCount');
  const message = field('message');
  const website = field('website');

  if (gymName.length < 2 || contactName.length < 2) {
    return { status: 'error', message: 'Please add your gym’s name and your name.' };
  }
  if (!isValidEmail(email)) {
    return { status: 'error', message: 'Please enter a valid email address.' };
  }
  if (phone && !isLikelyPhone(phone)) {
    return { status: 'error', message: 'That phone number doesn’t look right.' };
  }

  try {
    const response = await serverApiFetch('/leads', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        gymName,
        contactName,
        email,
        ...(phone && { phone }),
        ...(city && { city }),
        ...(MEMBER_BANDS.has(memberCount) && { memberCount }),
        ...(message && { message: message.slice(0, 2000) }),
        ...(website && { website }),
      }),
    });

    if (response.status === 429) {
      return { status: 'error', message: 'Too many attempts. Please wait a minute and try again.' };
    }
    if (!response.ok) {
      return { status: 'error', message: 'We couldn’t send that just now. Please try again or email us.' };
    }
  } catch {
    return { status: 'error', message: 'We couldn’t reach our server. Please try again or email us.' };
  }

  return { status: 'success' };
}

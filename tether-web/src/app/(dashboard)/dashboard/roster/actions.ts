'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { requireStaffSession } from '@/lib/auth';
import { serverApiFetch } from '@/lib/server-api';
import { isLikelyPhone, isValidEmail } from '@/lib/validation';

async function apiPost(path: string, body: unknown, token: string) {
  const response = await serverApiFetch(path, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify(body),
    token,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || `Request failed: ${path}`);
  }

  return response.json();
}

export async function addRosterEntry(formData: FormData) {
  const session = await requireStaffSession();
  const email = String(formData.get('email') ?? '').trim().toLowerCase();
  const phone = String(formData.get('phone') ?? '').trim();
  const memberName = String(formData.get('memberName') ?? '').trim();
  const externalMemberId = String(formData.get('externalMemberId') ?? '').trim();

  if (!email && !phone) {
    redirect('/dashboard/roster?error=Add%20at%20least%20an%20email%20or%20phone.');
  }
  if (email && !isValidEmail(email)) {
    redirect('/dashboard/roster?error=Enter%20a%20valid%20email%20address.');
  }
  if (phone && !isLikelyPhone(phone)) {
    redirect('/dashboard/roster?error=Enter%20a%20valid%20phone%20number.');
  }

  try {
    await apiPost(
      '/roster/entry',
      {
        gymId: session.gymId,
        ...(email ? { email } : {}),
        ...(phone ? { phone } : {}),
        ...(memberName ? { memberName } : {}),
        ...(externalMemberId ? { externalMemberId } : {}),
      },
      session.accessToken,
    );
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to add roster entry.';
    redirect(`/dashboard/roster?error=${encodeURIComponent(message)}`);
  }

  revalidatePath('/dashboard/roster');
  redirect('/dashboard/roster');
}

export async function importRosterCsv(formData: FormData) {
  const session = await requireStaffSession();
  const csvContent = String(formData.get('csvContent') ?? '').trim();

  if (!csvContent) {
    redirect('/dashboard/roster?error=Paste%20CSV%20content%20first.');
  }
  if (!csvContent.includes('\n') || !csvContent.toLowerCase().includes('email')) {
    redirect('/dashboard/roster?error=CSV%20must%20include%20headers%20such%20as%20email%20or%20phone.');
  }

  try {
    const result = (await apiPost(
      '/roster/import-csv',
      { gymId: session.gymId, csvContent },
      session.accessToken,
    )) as Array<{ row: number; status?: string; message?: string }>;

    revalidatePath('/dashboard/roster');

    const rows = Array.isArray(result) ? result : [];
    const okCount = rows.filter((row) => row.status === 'ok').length;
    const errorRows = rows.filter((row) => row.status === 'error');
    const failedCount = errorRows.length;
    const errorPreview = errorRows
      .slice(0, 12)
      .map((row) => `Row ${row.row}: ${row.message ?? 'failed'}`)
      .join(' · ');

    const params = new URLSearchParams({
      message: `${okCount} imported, ${failedCount} failed`,
    });
    if (errorPreview) {
      params.set('importErrors', errorPreview);
    }
    redirect(`/dashboard/roster?${params.toString()}`);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to import CSV.';
    redirect(`/dashboard/roster?error=${encodeURIComponent(message)}`);
  }
}

export async function approveRosterEntry(formData: FormData) {
  const session = await requireStaffSession();
  const rosterId = String(formData.get('rosterId') ?? '').trim();

  if (!rosterId) {
    redirect('/dashboard/roster?error=Missing%20roster%20id.');
  }

  try {
    await apiPost(`/roster/approve/${rosterId}`, {}, session.accessToken);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to approve request.';
    redirect(`/dashboard/roster?error=${encodeURIComponent(message)}`);
  }

  revalidatePath('/dashboard/roster');
  redirect('/dashboard/roster?message=Pending%20request%20approved');
}

'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { requireStaffSession } from '@/lib/auth';
import { serverApiFetch } from '@/lib/server-api';
import { isValidNoticeTag } from '@/lib/validation';

async function apiRequest(
  path: string,
  method: 'POST' | 'PATCH' | 'DELETE',
  token: string,
  body?: unknown,
) {
  const response = await serverApiFetch(path, {
    method,
    headers: {
      'Content-Type': 'application/json',
    },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
    token,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || `${method} ${path} failed`);
  }

  return response.json();
}

export async function createNotice(formData: FormData) {
  const session = await requireStaffSession();
  const title = String(formData.get('title') ?? '').trim();
  const body = String(formData.get('body') ?? '').trim();
  const tag = String(formData.get('tag') ?? '').trim();
  const isPinned = formData.get('isPinned') === 'on';

  if (!title || !body || !tag) {
    redirect('/dashboard/notices?mode=new&error=Title,%20body,%20and%20tag%20are%20required.');
  }
  if (!isValidNoticeTag(tag)) {
    redirect('/dashboard/notices?mode=new&error=Choose%20a%20valid%20notice%20tag.');
  }

  try {
    await apiRequest('/staff/notices', 'POST', session.accessToken, {
      title,
      body,
      tag,
      isPinned,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to create notice.';
    redirect(`/dashboard/notices?mode=new&error=${encodeURIComponent(message)}`);
  }

  revalidatePath('/dashboard/notices');
  redirect('/dashboard/notices?message=Notice%20created');
}

export async function updateNotice(formData: FormData) {
  const session = await requireStaffSession();
  const noticeId = String(formData.get('noticeId') ?? '').trim();
  const title = String(formData.get('title') ?? '').trim();
  const body = String(formData.get('body') ?? '').trim();
  const tag = String(formData.get('tag') ?? '').trim();
  const isPinned = formData.get('isPinned') === 'on';

  if (!noticeId || !title || !body || !tag) {
    redirect('/dashboard/notices?error=Notice%20id,%20title,%20body,%20and%20tag%20are%20required.');
  }
  if (!isValidNoticeTag(tag)) {
    redirect(`/dashboard/notices?noticeId=${noticeId}&error=Choose%20a%20valid%20notice%20tag.`);
  }

  try {
    await apiRequest(`/staff/notices/${noticeId}`, 'PATCH', session.accessToken, {
      title,
      body,
      tag,
      isPinned,
    });
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to update notice.';
    redirect(`/dashboard/notices?noticeId=${noticeId}&error=${encodeURIComponent(message)}`);
  }

  revalidatePath('/dashboard/notices');
  redirect(`/dashboard/notices?noticeId=${noticeId}&message=Notice%20updated`);
}

export async function softDeleteNotice(formData: FormData) {
  const session = await requireStaffSession();
  const noticeId = String(formData.get('noticeId') ?? '').trim();

  if (!noticeId) {
    redirect('/dashboard/notices?error=Missing%20notice%20id.');
  }

  try {
    await apiRequest(`/staff/notices/${noticeId}`, 'DELETE', session.accessToken);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to delete notice.';
    redirect(`/dashboard/notices?noticeId=${noticeId}&error=${encodeURIComponent(message)}`);
  }

  revalidatePath('/dashboard/notices');
  redirect('/dashboard/notices?message=Notice%20deleted');
}

export async function restoreNotice(formData: FormData) {
  const session = await requireStaffSession();
  const noticeId = String(formData.get('noticeId') ?? '').trim();

  if (!noticeId) {
    redirect('/dashboard/notices?error=Missing%20notice%20id.');
  }

  try {
    await apiRequest(`/staff/notices/${noticeId}/restore`, 'POST', session.accessToken, {});
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to restore notice.';
    redirect(`/dashboard/notices?noticeId=${noticeId}&error=${encodeURIComponent(message)}`);
  }

  revalidatePath('/dashboard/notices');
  redirect(`/dashboard/notices?noticeId=${noticeId}&message=Notice%20restored`);
}

'use server';

import { revalidatePath } from 'next/cache';
import { redirect } from 'next/navigation';
import { requireStaffSession } from '@/lib/auth';
import { serverApiFetch } from '@/lib/server-api';

async function apiRequest(
  path: string,
  method: 'POST' | 'DELETE',
  token: string,
) {
  const response = await serverApiFetch(path, {
    method,
    token,
  });

  if (!response.ok) {
    const text = await response.text();
    throw new Error(text || `${method} ${path} failed`);
  }

  return response.json();
}

function returnPath(formData: FormData) {
  const value = String(formData.get('returnTo') ?? '');
  // Only same-app dashboard paths; never an absolute or protocol-relative URL.
  return /^\/dashboard(\/[\w/-]*)?$/.test(value) ? value : '/dashboard/feed';
}

function withParam(path: string, key: 'message' | 'error', value: string) {
  return `${path}?${key}=${encodeURIComponent(value)}`;
}

export async function dismissFlag(formData: FormData) {
  const session = await requireStaffSession();
  const postId = String(formData.get('postId') ?? '').trim();
  const back = returnPath(formData);

  if (!postId) {
    redirect(withParam(back, 'error', 'Missing post id.'));
  }

  try {
    await apiRequest(`/staff/social/posts/${postId}/dismiss-flag`, 'POST', session.accessToken);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to dismiss flag.';
    redirect(withParam(back, 'error', message));
  }

  revalidatePath('/dashboard', 'layout');
  redirect(withParam(back, 'message', 'Flag dismissed'));
}

export async function softDeletePost(formData: FormData) {
  const session = await requireStaffSession();
  const postId = String(formData.get('postId') ?? '').trim();
  const back = returnPath(formData);

  if (!postId) {
    redirect(withParam(back, 'error', 'Missing post id.'));
  }

  try {
    await apiRequest(`/staff/social/posts/${postId}`, 'DELETE', session.accessToken);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to delete post.';
    redirect(withParam(back, 'error', message));
  }

  revalidatePath('/dashboard', 'layout');
  redirect(withParam(back, 'message', 'Post removed'));
}

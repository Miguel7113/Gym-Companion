import { BadgeCheck, Flag, Heart, MessageCircle, Trash2 } from 'lucide-react';
import type { ModerationPost } from '@/lib/api';
import { initials, timeAgo } from '@/lib/format';
import { dismissFlag, softDeletePost } from '@/app/(dashboard)/dashboard/feed/actions';

export function FeedCard({
  post,
  returnTo,
  showFlagActions = false,
}: {
  post: ModerationPost;
  returnTo: string;
  showFlagActions?: boolean;
}) {
  return (
    <article className="tdash-feed-card group flex gap-2.5">
      <div
        className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-surface-muted text-[13px] font-medium ${
          post.authorRole ? 'text-sky-300' : 'text-neutral-300'
        }`}
        aria-hidden
      >
        {initials(post.authorName)}
      </div>
      <div className="min-w-0 flex-1">
        <div className="flex flex-wrap items-center gap-2">
          <span className="text-sm font-medium">{post.authorName}</span>
          {post.authorRole ? (
            <span className="rounded-md bg-surface-muted px-2 py-px text-xs capitalize text-neutral-400">
              {post.authorRole}
            </span>
          ) : null}
          {post.isFlagged ? (
            <span className="flex items-center gap-1 rounded-md bg-rose-400/10 px-2 py-px text-xs text-rose-400">
              <Flag size={10} aria-hidden /> {post.flagCount} flag{post.flagCount === 1 ? '' : 's'}
            </span>
          ) : null}
          <time className="text-xs text-neutral-500" dateTime={post.createdAt}>
            {timeAgo(post.createdAt)}
          </time>
          {!showFlagActions ? (
            <form action={softDeletePost} className="ml-auto">
              <input type="hidden" name="postId" value={post.id} />
              <input type="hidden" name="returnTo" value={returnTo} />
              <button type="submit" className="tdash-reveal" title="Remove post" aria-label={`Remove post by ${post.authorName}`}>
                <Trash2 size={14} aria-hidden />
              </button>
            </form>
          ) : null}
        </div>
        <p className="my-1 whitespace-pre-line text-sm leading-relaxed text-neutral-300">
          {post.content || (post.achievementType ? `Shared a ${post.achievementType.replace(/_/g, ' ')}` : 'Shared a workout')}
        </p>
        {post.imageUrl ? (
          // eslint-disable-next-line @next/next/no-img-element
          <img
            src={post.imageUrl}
            alt=""
            className="mb-1 mt-1.5 max-h-56 rounded-lg border border-line object-cover"
          />
        ) : null}
        <div className="flex flex-wrap items-center gap-4 text-xs text-neutral-400">
          <span className="flex items-center gap-1.5">
            <Heart size={14} aria-hidden /> <span className="tnum">{post.likeCount}</span>
            <span className="sr-only">likes</span>
          </span>
          <span className="flex items-center gap-1.5">
            <MessageCircle size={14} aria-hidden /> <span className="tnum">{post.commentCount}</span>
            <span className="sr-only">comments</span>
          </span>
          {post.coachCertification ? (
            <span className="flex items-center gap-1.5 text-sky-300">
              <BadgeCheck size={14} aria-hidden /> Certified by {post.coachCertification.coachName}
            </span>
          ) : null}
        </div>
        {showFlagActions ? (
          <div className="mt-3 flex flex-wrap gap-2">
            <form action={dismissFlag}>
              <input type="hidden" name="postId" value={post.id} />
              <input type="hidden" name="returnTo" value={returnTo} />
              <button type="submit" className="btn btn-secondary">
                Dismiss flag
              </button>
            </form>
            <form action={softDeletePost}>
              <input type="hidden" name="postId" value={post.id} />
              <input type="hidden" name="returnTo" value={returnTo} />
              <button type="submit" className="btn btn-danger">
                Remove post
              </button>
            </form>
          </div>
        ) : null}
      </div>
    </article>
  );
}

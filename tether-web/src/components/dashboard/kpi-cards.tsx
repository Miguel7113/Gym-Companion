'use client';

import Link from 'next/link';
import { motion } from 'framer-motion';
import { Activity, ClipboardList, Dumbbell, Users } from 'lucide-react';
import { cardIn, staggerParent, useCountUp } from '@/lib/motion';

const ICONS = {
  members: Users,
  active: Activity,
  workouts: Dumbbell,
  pending: ClipboardList,
} as const;

export type KpiItem = {
  label: string;
  value: number;
  icon: keyof typeof ICONS;
  delta: string;
  tone: 'up' | 'down' | 'neutral' | 'warn';
  live?: boolean;
  href?: string;
};

const TONE_CLASS: Record<KpiItem['tone'], string> = {
  up: 'bg-emerald-400/10 text-emerald-400',
  down: 'bg-rose-400/10 text-rose-400',
  warn: 'bg-amber-400/10 text-amber-400',
  neutral: 'bg-white/5 text-neutral-400',
};

function KpiCard({ item, index }: { item: KpiItem; index: number }) {
  const display = useCountUp(item.value, 900, 150 + index * 60);
  const Icon = ICONS[item.icon];

  const body = (
    <>
      <span className="absolute right-3.5 top-3.5 flex h-7 w-7 items-center justify-center rounded-lg bg-chart-20 text-chart">
        <Icon size={14} aria-hidden />
      </span>
      <div className="mb-1 flex items-center gap-1.5 text-xs text-neutral-400">
        {item.live ? (
          <span className="relative flex h-1.5 w-1.5" aria-hidden>
            <span className="absolute h-full w-full animate-ping rounded-full bg-emerald-400 opacity-60 motion-reduce:animate-none" />
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-400" />
          </span>
        ) : null}
        {item.label}
      </div>
      <div
        className={`tnum text-[28px] font-medium leading-[1.1] ${item.live ? 'text-chart' : ''}`}
        aria-label={`${item.label}: ${item.value.toLocaleString()}`}
      >
        {display.toLocaleString()}
      </div>
      <div className="mt-1.5">
        <span className={`rounded-md px-2 py-px text-xs font-medium ${TONE_CLASS[item.tone]}`}>
          {item.delta}
        </span>
      </div>
    </>
  );

  const className = `tdash-card card-lift relative ${item.live ? 'tdash-card-live' : ''}`;

  return (
    <motion.div variants={cardIn}>
      {item.href ? (
        <Link href={item.href} className={`${className} h-full`}>
          {body}
        </Link>
      ) : (
        <div className={`${className} h-full`}>{body}</div>
      )}
    </motion.div>
  );
}

export function KpiGrid({ items }: { items: KpiItem[] }) {
  return (
    <motion.div
      className="tdash-grid-kpi"
      variants={staggerParent}
      initial="hidden"
      animate="show"
    >
      {items.map((item, i) => (
        <KpiCard key={item.label} item={item} index={i} />
      ))}
    </motion.div>
  );
}

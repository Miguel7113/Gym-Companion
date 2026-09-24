'use client';

import Link from 'next/link';
import { Plus } from 'lucide-react';
import { motion, useReducedMotion } from 'framer-motion';
import type { GymDashboard } from '@/lib/api';

const VISIBLE = 5;

export function CoachStack({ coaches }: { coaches: GymDashboard['coaches'] }) {
  const reduce = useReducedMotion();
  const visible = coaches.list.slice(0, VISIBLE);
  const overflow = coaches.list.length - visible.length;

  return (
    <div className="tdash-card card-lift">
      <div className="flex items-center justify-between">
        <h2 className="tdash-card-title">Coaches</h2>
        <Link
          href="/dashboard/settings"
          className="tdash-icon-btn"
          style={{ width: 28, height: 28, borderRadius: 999 }}
          aria-label="Invite a coach"
          title="Invite a coach"
        >
          <Plus size={13} aria-hidden />
        </Link>
      </div>
      {coaches.total === 0 ? (
        <p className="tdash-empty" style={{ marginTop: 10 }}>
          No coaches yet. Invite one from Settings.
        </p>
      ) : (
        <div className="mt-2.5 flex items-center">
          <ul className="m-0 flex list-none items-center p-0">
            {visible.map((coach, i) => (
              <motion.li
                key={coach.staffId}
                initial={reduce ? false : { opacity: 0, x: -6 }}
                animate={{ opacity: 1, x: 0 }}
                transition={{ delay: 0.4 + i * 0.07 }}
                title={`${coach.name}${coach.isTrainingNow ? ' · training now' : ''}${
                  coach.hasAppAccount ? ` · ${coach.programCount} programs` : ' · not signed in yet'
                }`}
                className={`relative flex h-[34px] w-[34px] items-center justify-center rounded-full border-2 border-surface bg-surface-muted text-xs font-medium ${
                  coach.hasAppAccount ? 'text-neutral-200' : 'text-neutral-500'
                } ${i > 0 ? '-ml-2' : ''}`}
              >
                {coach.name.slice(0, 1).toUpperCase()}
                {coach.isTrainingNow ? (
                  <span
                    className="absolute -right-0.5 -top-0.5 h-2.5 w-2.5 rounded-full border-2 border-surface bg-emerald-400"
                    aria-hidden
                  />
                ) : null}
              </motion.li>
            ))}
            {overflow > 0 ? (
              <li className="-ml-2 flex h-[34px] w-[34px] items-center justify-center rounded-full border-2 border-surface bg-surface-high text-[11px] font-medium text-neutral-300">
                +{overflow}
              </li>
            ) : null}
          </ul>
          <div className="ml-auto text-right text-xs text-neutral-400">
            <span className="tnum text-base font-medium text-neutral-100">{coaches.trainingNow}</span>{' '}
            training now
            <br />
            <span className="tnum text-base font-medium text-neutral-100">{coaches.total}</span> total
          </div>
        </div>
      )}
    </div>
  );
}

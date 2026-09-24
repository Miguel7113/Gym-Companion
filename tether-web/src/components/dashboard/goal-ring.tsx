'use client';

import { motion, useReducedMotion } from 'framer-motion';
import type { GymDashboard } from '@/lib/api';
import { easeOut } from '@/lib/motion';

const R = 38;
const C = 2 * Math.PI * R;

export function GoalRing({ goal }: { goal: GymDashboard['weeklyGoal'] }) {
  const reduce = useReducedMotion();
  const hasTarget = goal.target > 0;
  const pct = hasTarget ? Math.min(goal.current / goal.target, 1) : 0;
  const shownPct = hasTarget ? Math.round((goal.current / goal.target) * 100) : 0;

  return (
    <div className="tdash-card card-lift items-center justify-center gap-2">
      <h2 className="tdash-card-title self-start">Weekly workout pace</h2>
      {hasTarget ? (
        <>
          <svg
            viewBox="0 0 96 96"
            style={{ width: 96 }}
            role="img"
            aria-label={`${shownPct}% of the four-week weekly average`}
          >
            <circle cx="48" cy="48" r={R} fill="none" stroke="#1c1e22" strokeWidth="9" />
            <motion.circle
              cx="48"
              cy="48"
              r={R}
              fill="none"
              stroke="#3b82f6"
              strokeWidth="9"
              strokeLinecap="round"
              transform="rotate(-90 48 48)"
              initial={reduce ? false : { strokeDasharray: `0 ${C}` }}
              animate={{ strokeDasharray: `${pct * C} ${C}` }}
              transition={{ duration: 1.1, delay: 0.4, ease: easeOut }}
            />
            <text
              x="48"
              y="54"
              textAnchor="middle"
              fontSize="19"
              fontWeight="500"
              fill="currentColor"
              style={{ fontVariantNumeric: 'tabular-nums' }}
            >
              {shownPct}%
            </text>
          </svg>
          <div className="text-center text-xs text-neutral-400">
            <span className="tnum">{goal.current.toLocaleString()}</span> of{' '}
            <span className="tnum">{goal.target.toLocaleString()}</span> (4-week avg)
            <br />
            {goal.daysLeft === 0 ? 'Last day of the week' : `${goal.daysLeft} day${goal.daysLeft === 1 ? '' : 's'} left`}
          </div>
        </>
      ) : (
        <p className="tdash-empty self-start">
          <span className="tnum text-neutral-200">{goal.current}</span> workouts so far this week.
          A pace target appears once there are four weeks of history.
        </p>
      )}
    </div>
  );
}

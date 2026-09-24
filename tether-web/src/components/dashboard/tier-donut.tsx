'use client';

import { motion, useReducedMotion } from 'framer-motion';
import { Cell, Pie, PieChart, ResponsiveContainer } from 'recharts';
import type { GymDashboard } from '@/lib/api';
import { easeOut, useCountUp } from '@/lib/motion';

/** Sequential steps of the single accent; anything past the fourth tier folds into "Other". */
const STEPS = ['#3b82f6', '#3b82f69e', '#3b82f661', '#3b82f633'];

function titleCase(value: string) {
  return value
    .replace(/[_-]+/g, ' ')
    .replace(/\b\w/g, (c) => c.toUpperCase());
}

export function TierDonut({ tiers }: { tiers: GymDashboard['tiers'] }) {
  const reduce = useReducedMotion();
  const data =
    tiers.length > STEPS.length
      ? [
          ...tiers.slice(0, STEPS.length - 1),
          {
            name: 'other',
            value: tiers.slice(STEPS.length - 1).reduce((s, t) => s + t.value, 0),
          },
        ]
      : tiers;
  const total = data.reduce((s, t) => s + t.value, 0);
  const shownTotal = useCountUp(total, 900, 300);

  return (
    <div className="tdash-card card-lift">
      <div className="tdash-card-head">
        <h2 className="tdash-card-title">Membership tiers</h2>
        <span className="tdash-card-meta">All members</span>
      </div>
      {total === 0 ? (
        <p className="tdash-empty">No members yet.</p>
      ) : (
        <div className="flex items-center gap-4">
          <div className="relative h-[132px] w-[132px] shrink-0" aria-hidden>
            <ResponsiveContainer>
              <PieChart>
                <Pie
                  data={data}
                  dataKey="value"
                  nameKey="name"
                  innerRadius={44}
                  outerRadius={62}
                  startAngle={90}
                  endAngle={-270}
                  stroke="none"
                  isAnimationActive={!reduce}
                  animationDuration={900}
                >
                  {data.map((tier, i) => (
                    <Cell key={tier.name} fill={STEPS[i]} />
                  ))}
                </Pie>
              </PieChart>
            </ResponsiveContainer>
            <div className="pointer-events-none absolute inset-0 flex flex-col items-center justify-center">
              <span className="tnum text-[21px] font-medium leading-none">
                {shownTotal.toLocaleString()}
              </span>
              <span className="mt-1 text-[10px] text-neutral-400">members</span>
            </div>
          </div>
          <ul className="m-0 flex min-w-0 flex-1 list-none flex-col gap-2 p-0">
            {data.map((tier, i) => (
              <motion.li
                key={tier.name}
                initial={{ opacity: 0, y: 10 }}
                animate={{ opacity: 1, y: 0 }}
                transition={{ delay: 0.3 + i * 0.08, duration: 0.45, ease: easeOut }}
                className="flex items-center gap-2 text-[13px]"
              >
                <span
                  className="h-2.5 w-2.5 shrink-0 rounded-[3px]"
                  style={{ background: STEPS[i] }}
                  aria-hidden
                />
                <span className="flex-1 truncate text-neutral-300">{titleCase(tier.name)}</span>
                <span className="tnum text-neutral-500">{tier.value}</span>
                <span className="tnum w-9 text-right font-medium">
                  {Math.round((tier.value / total) * 100)}%
                </span>
              </motion.li>
            ))}
          </ul>
        </div>
      )}
    </div>
  );
}

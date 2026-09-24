'use client';

import { motion, useReducedMotion } from 'framer-motion';
import type { GymDashboard } from '@/lib/api';
import { easeOut } from '@/lib/motion';

export function ProgramList({ programs }: { programs: GymDashboard['topPrograms'] }) {
  const reduce = useReducedMotion();
  if (programs.length === 0) {
    return <p className="tdash-empty">No programs or routines were used in this period.</p>;
  }
  const top = programs[0].sessions;

  return (
    <ul className="m-0 flex list-none flex-col gap-2.5 p-0">
      {programs.map((program, i) => {
        const pct = Math.round((program.sessions / top) * 100);
        return (
          <li key={program.id}>
            <div className="flex justify-between gap-2 text-[13px]">
              <span className="truncate font-medium">{program.name}</span>
              <span className="tnum shrink-0 text-neutral-400">
                {program.sessions} session{program.sessions === 1 ? '' : 's'}
              </span>
            </div>
            <div className="mb-[5px] mt-0.5 text-xs text-neutral-500">
              {program.coachName ? `Coach ${program.coachName}` : program.source === 'system' ? 'Tether program' : 'Member routine'}
            </div>
            <div className="h-1 overflow-hidden rounded bg-surface-muted">
              <motion.div
                className="h-full rounded bg-chart"
                initial={reduce ? false : { width: 0 }}
                whileInView={{ width: `${pct}%` }}
                viewport={{ once: true }}
                style={reduce ? { width: `${pct}%` } : undefined}
                transition={{ duration: 0.8, delay: 0.2 + i * 0.1, ease: easeOut }}
              />
            </div>
          </li>
        );
      })}
    </ul>
  );
}

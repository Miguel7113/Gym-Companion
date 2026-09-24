'use client';

import { motion, useReducedMotion } from 'framer-motion';
import type { GymDashboard } from '@/lib/api';

function hourLabel(hour: number) {
  if (hour === 0) return '12a';
  if (hour === 12) return '12p';
  return hour < 12 ? `${hour}a` : `${hour - 12}p`;
}

export function BusyHoursHeatmap({ busyHours }: { busyHours: GymDashboard['busyHours'] }) {
  const reduce = useReducedMotion();
  const { days, hours, grid, max, windowDays } = busyHours;

  let peakCell: { row: number; col: number } | null = null;
  if (max > 0) {
    outer: for (let r = 0; r < grid.length; r++) {
      for (let c = 0; c < grid[r].length; c++) {
        if (grid[r][c] === max) {
          peakCell = { row: r, col: c };
          break outer;
        }
      }
    }
  }

  return (
    <div className="tdash-card card-lift">
      <div className="tdash-card-head">
        <h2 className="tdash-card-title">Busy hours</h2>
        <span className="tdash-card-meta">Workout starts · last {windowDays} days</span>
      </div>
      {max === 0 ? (
        <p className="tdash-empty">Not enough workouts yet to show a pattern.</p>
      ) : (
        <>
          <div
            className="grid gap-1"
            style={{ gridTemplateColumns: `28px repeat(${hours.length}, minmax(0, 1fr))` }}
            role="img"
            aria-label={
              peakCell
                ? `Busiest time is ${days[peakCell.row]} around ${hourLabel(hours[peakCell.col])}`
                : 'Busy hours heatmap'
            }
          >
            {grid.map((row, r) => (
              <div key={days[r]} className="contents">
                <span className="self-center text-[10px] text-neutral-500">{days[r]}</span>
                {row.map((count, c) => {
                  const level = count / max;
                  const isPeak = peakCell?.row === r && peakCell.col === c;
                  return (
                    <motion.span
                      key={c}
                      title={`${days[r]} ${hourLabel(hours[c])} · ${count} workout${count === 1 ? '' : 's'}`}
                      className="aspect-square w-full rounded-full"
                      initial={reduce ? false : { opacity: 0, scale: 0.4 }}
                      animate={{ opacity: 1, scale: 1 }}
                      transition={{ delay: 0.35 + (r * row.length + c) * 0.004, duration: 0.3 }}
                      whileHover={reduce ? undefined : { scale: 1.4 }}
                      style={{
                        background:
                          count === 0
                            ? 'rgb(255 255 255 / 5%)'
                            : `color-mix(in srgb, #3b82f6 ${Math.round(20 + level * 80)}%, transparent)`,
                        boxShadow: isPeak ? '0 0 0 1.5px #f5f5f5' : undefined,
                      }}
                    />
                  );
                })}
              </div>
            ))}
          </div>
          <div
            className="mt-2 flex justify-between text-xs text-neutral-400"
            style={{ paddingLeft: 32 }}
          >
            <span>{hourLabel(hours[0])}</span>
            <span>12p</span>
            <span>{hourLabel(hours[hours.length - 1])}</span>
          </div>
          {peakCell ? (
            <p className="m-0 mt-2 text-xs text-neutral-400">
              Peak: <span className="text-neutral-200">{days[peakCell.row]} {hourLabel(hours[peakCell.col])}</span>
            </p>
          ) : null}
        </>
      )}
    </div>
  );
}

'use client';

import { useReducedMotion } from 'framer-motion';
import {
  Area,
  CartesianGrid,
  ComposedChart,
  Line,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from 'recharts';
import type { GymDashboard } from '@/lib/api';

const ACCENT = '#3b82f6';
const AXIS = { fontSize: 11, fill: '#737373' };

export function ActivityChart({
  activity,
  height = 230,
}: {
  activity: GymDashboard['activity'];
  height?: number;
}) {
  const reduce = useReducedMotion();
  const animate = !reduce;
  const total = activity.points.reduce((sum, p) => sum + (p.current ?? 0), 0);

  return (
    <div className="tdash-card card-lift">
      <div className="mb-2 flex flex-wrap items-center gap-x-4 gap-y-1 text-xs text-neutral-400">
        <h2 className="tdash-card-title mr-auto">Workouts logged</h2>
        <span className="flex items-center gap-1.5">
          <span className="h-0.5 w-3.5 rounded bg-chart" aria-hidden />
          {activity.currentLabel}
        </span>
        <span className="flex items-center gap-1.5">
          <span className="w-3.5 border-t border-dashed border-neutral-500" aria-hidden />
          {activity.previousLabel}
        </span>
      </div>
      {total === 0 && activity.points.every((p) => p.previous === 0) ? (
        <p className="tdash-empty" style={{ height, display: 'grid', placeItems: 'center' }}>
          No workouts logged in this period yet.
        </p>
      ) : (
        <div role="img" aria-label={`${total} workouts logged, ${activity.currentLabel.toLowerCase()}`}>
          <ResponsiveContainer width="100%" height={height}>
            <ComposedChart
              data={activity.points}
              margin={{ top: 8, right: 8, bottom: 0, left: -18 }}
            >
              <CartesianGrid stroke="rgba(255,255,255,.07)" vertical={false} />
              <XAxis
                dataKey="label"
                tick={AXIS}
                axisLine={false}
                tickLine={false}
                interval="preserveStartEnd"
                minTickGap={16}
              />
              <YAxis
                tick={AXIS}
                axisLine={false}
                tickLine={false}
                allowDecimals={false}
                domain={[0, 'auto']}
              />
              <Tooltip
                contentStyle={{
                  background: '#17181B',
                  border: '1px solid rgba(255,255,255,.07)',
                  borderRadius: 10,
                  fontSize: 13,
                }}
                labelStyle={{ color: '#a3a3a3' }}
                formatter={(value, name) => [
                  value ?? '—',
                  name === 'current' ? activity.currentLabel : activity.previousLabel,
                ]}
              />
              <Area
                type="monotone"
                dataKey="current"
                stroke="none"
                fill={ACCENT}
                fillOpacity={0.08}
                isAnimationActive={animate}
                animationDuration={800}
                legendType="none"
                tooltipType="none"
              />
              <Line
                type="monotone"
                dataKey="previous"
                stroke="#737373"
                strokeWidth={2}
                strokeDasharray="5 5"
                dot={false}
                isAnimationActive={animate}
                animationDuration={900}
                animationEasing="ease-out"
              />
              <Line
                type="monotone"
                dataKey="current"
                stroke={ACCENT}
                strokeWidth={2.5}
                connectNulls={false}
                dot={
                  activity.points.length <= 14
                    ? { r: 3.5, fill: '#0B0C0E', stroke: ACCENT, strokeWidth: 2 }
                    : false
                }
                activeDot={{ r: 4.5 }}
                isAnimationActive={animate}
                animationDuration={900}
                animationEasing="ease-out"
              />
            </ComposedChart>
          </ResponsiveContainer>
        </div>
      )}
    </div>
  );
}

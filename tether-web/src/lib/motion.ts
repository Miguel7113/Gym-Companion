'use client';

import { useEffect, useRef, useState } from 'react';
import { useReducedMotion, type Variants } from 'framer-motion';

export const easeOut = [0.22, 0.9, 0.3, 1] as const;

export const staggerParent: Variants = {
  hidden: {},
  show: { transition: { staggerChildren: 0.06, delayChildren: 0.05 } },
};

export const cardIn: Variants = {
  hidden: { opacity: 0, y: 10 },
  show: { opacity: 1, y: 0, transition: { duration: 0.45, ease: easeOut } },
};

/** Animates from the previously shown value, so refreshed data doesn't restart at zero. */
export function useCountUp(target: number, duration = 900, delay = 150) {
  const reduce = useReducedMotion();
  const [value, setValue] = useState(reduce ? target : 0);
  const shown = useRef(value);

  useEffect(() => {
    if (reduce) {
      shown.current = target;
      setValue(target);
      return;
    }
    const from = shown.current;
    let frame = 0;
    let start: number | undefined;
    const timer = setTimeout(() => {
      const step = (ts: number) => {
        start ??= ts;
        const p = Math.min((ts - start) / duration, 1);
        const next = Math.round(from + (target - from) * (1 - Math.pow(1 - p, 3)));
        shown.current = next;
        setValue(next);
        if (p < 1) frame = requestAnimationFrame(step);
      };
      frame = requestAnimationFrame(step);
    }, delay);
    return () => {
      clearTimeout(timer);
      cancelAnimationFrame(frame);
    };
  }, [target, duration, delay, reduce]);

  return value;
}

'use client';

import { useLayoutEffect, useRef, useState, type ReactNode } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';
import { Check } from 'lucide-react';
import { PhoneFrame } from './app-screens';

gsap.registerPlugin(ScrollTrigger);

export type ShowcaseStep = {
  title: string;
  body: string;
  points: string[];
  screen: ReactNode;
};

export function PhoneShowcase({ steps }: { steps: ShowcaseStep[] }) {
  const [active, setActive] = useState(0);
  const stepsRef = useRef<HTMLDivElement>(null);

  useLayoutEffect(() => {
    const el = stepsRef.current;
    if (!el) return;
    const ctx = gsap.context(() => {
      Array.from(el.children).forEach((step, index) => {
        ScrollTrigger.create({
          trigger: step,
          start: 'top 55%',
          end: 'bottom 55%',
          onToggle: (self) => self.isActive && setActive(index),
        });
      });
    }, el);
    return () => ctx.revert();
  }, []);

  return (
    <div className="mk-showcase">
      <div className="mk-showcase-steps" ref={stepsRef}>
        {steps.map((step, index) => (
          <article key={step.title} className="mk-showcase-step" data-active={index === active}>
            <span className="mk-showcase-num">
              {String(index + 1).padStart(2, '0')} / {String(steps.length).padStart(2, '0')}
            </span>
            <h3>{step.title}</h3>
            <p className="mk-lead">{step.body}</p>
            <ul>
              {step.points.map((point) => (
                <li key={point}>
                  <Check size={18} /> {point}
                </li>
              ))}
            </ul>
            <div className="mk-showcase-inline">
              <PhoneFrame width={280}>{step.screen}</PhoneFrame>
            </div>
          </article>
        ))}
      </div>
      <div className="mk-showcase-stage" aria-hidden="true">
        <div className="mk-showcase-glow" />
        <div className="mk-showcase-screens">
          {steps.map((step, index) => (
            <div
              key={step.title}
              className="mk-showcase-screen"
              data-active={index === active}
              style={{ display: 'grid', placeItems: 'center' }}
            >
              <PhoneFrame width={340}>{step.screen}</PhoneFrame>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}

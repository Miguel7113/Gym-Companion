'use client';

import { useLayoutEffect, useRef, type ElementType, type ReactNode } from 'react';
import { gsap } from 'gsap';
import { ScrollTrigger } from 'gsap/ScrollTrigger';

gsap.registerPlugin(ScrollTrigger);

const EASE = 'expo.out';

function reducedMotion() {
  return window.matchMedia('(prefers-reduced-motion: reduce)').matches;
}

function useGsap<T extends HTMLElement>(setup: (el: T) => void) {
  const ref = useRef<T>(null);
  useLayoutEffect(() => {
    const el = ref.current;
    if (!el) return;
    if (reducedMotion()) {
      gsap.set(el.querySelectorAll('[data-reveal], .mk-w > span, .mk-scrub-word'), {
        clearProps: 'all',
        opacity: 1,
      });
      if (el.hasAttribute('data-reveal')) gsap.set(el, { opacity: 1 });
      return;
    }
    const ctx = gsap.context(() => setup(el), el);
    return () => ctx.revert();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);
  return ref;
}

type RevealProps = {
  as?: ElementType;
  children: ReactNode;
  className?: string;
  delay?: number;
  y?: number;
  /** Animate direct children one after another instead of the wrapper. */
  stagger?: number;
  /** Fire on mount instead of on scroll (for above-the-fold content). */
  immediate?: boolean;
  style?: React.CSSProperties;
  id?: string;
};

export function Reveal({
  as: Tag = 'div',
  children,
  className,
  delay = 0,
  y = 48,
  stagger,
  immediate,
  style,
  id,
}: RevealProps) {
  const ref = useGsap<HTMLElement>((el) => {
    const targets = stagger ? Array.from(el.children) : el;
    if (stagger) gsap.set(el, { opacity: 1 });
    gsap.fromTo(
      targets,
      { opacity: 0, y },
      {
        opacity: 1,
        y: 0,
        duration: 1.2,
        delay,
        ease: EASE,
        stagger: stagger ?? 0,
        scrollTrigger: immediate ? undefined : { trigger: el, start: 'top 88%', once: true },
      },
    );
  });

  return (
    <Tag ref={ref} className={className} style={style} id={id} data-reveal="">
      {children}
    </Tag>
  );
}

type SplitProps = {
  as?: ElementType;
  text: string;
  className?: string;
  delay?: number;
  immediate?: boolean;
  /** Words to colour with the accent. */
  accent?: string[];
  style?: React.CSSProperties;
};

/** Headline whose words rise out of a mask. Use "\n" for forced line breaks. */
export function SplitHeading({
  as: Tag = 'h2',
  text,
  className,
  delay = 0,
  immediate,
  accent = [],
  style,
}: SplitProps) {
  const ref = useGsap<HTMLElement>((el) => {
    gsap.to(el.querySelectorAll('.mk-w > span'), {
      y: 0,
      duration: 1.3,
      delay,
      ease: EASE,
      stagger: 0.06,
      scrollTrigger: immediate ? undefined : { trigger: el, start: 'top 85%', once: true },
    });
  });

  const lines = text.split('\n');
  const bare = (word: string) => word.replace(/[.,!?]/g, '');
  const accented = new Set(accent.map(bare));

  return (
    <Tag ref={ref} className={className} style={style} data-split="" aria-label={text.replace(/\n/g, ' ')}>
      {lines.map((line, li) => (
        <span key={li} aria-hidden="true" style={{ display: 'block' }}>
          {line.split(' ').map((word, wi) => (
            <span key={wi}>
              <span className="mk-w">
                <span className={accented.has(bare(word)) ? 'mk-accent' : undefined}>
                  {word}
                </span>
              </span>{' '}
            </span>
          ))}
        </span>
      ))}
    </Tag>
  );
}

/** Paragraph whose words light up as it scrolls through the viewport. */
export function ScrubText({ text, className }: { text: string; className?: string }) {
  const ref = useGsap<HTMLParagraphElement>((el) => {
    gsap.to(el.querySelectorAll('.mk-scrub-word'), {
      opacity: 1,
      ease: 'none',
      stagger: 0.1,
      scrollTrigger: { trigger: el, start: 'top 80%', end: 'bottom 45%', scrub: true },
    });
  });

  return (
    <p ref={ref} className={className} data-scrub="">
      {text.split(' ').map((word, i) => (
        <span key={i} className="mk-scrub-word">
          {word}{' '}
        </span>
      ))}
    </p>
  );
}

/** Moves its content vertically at a different rate to the page. */
export function Parallax({
  children,
  speed = 12,
  className,
  style,
}: {
  children: ReactNode;
  speed?: number;
  className?: string;
  style?: React.CSSProperties;
}) {
  const ref = useGsap<HTMLDivElement>((el) => {
    gsap.fromTo(
      el,
      { yPercent: -speed / 2 },
      {
        yPercent: speed / 2,
        ease: 'none',
        scrollTrigger: { trigger: el.parentElement ?? el, start: 'top bottom', end: 'bottom top', scrub: true },
      },
    );
  });

  return (
    <div ref={ref} className={className} style={style}>
      {children}
    </div>
  );
}

/** Bars in the portal mockup grow when scrolled into view. */
export function GrowBars({ values, highlight }: { values: number[]; highlight: number }) {
  const ref = useGsap<HTMLDivElement>((el) => {
    gsap.from(el.children, {
      scaleY: 0,
      duration: 1.1,
      ease: EASE,
      stagger: 0.05,
      scrollTrigger: { trigger: el, start: 'top 90%', once: true },
    });
  });

  return (
    <div ref={ref} className="portal-bars">
      {values.map((value, i) => (
        <i key={i} style={{ height: `${value}%` }} data-hi={i === highlight} />
      ))}
    </div>
  );
}

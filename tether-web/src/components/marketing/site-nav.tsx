'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { useEffect, useState } from 'react';
import { ArrowRight, Menu, X } from 'lucide-react';
import { Logo } from './logo';
import { site } from './site';

export function SiteNav() {
  const pathname = usePathname();
  const [scrolled, setScrolled] = useState(false);
  const [open, setOpen] = useState(false);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 24);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  useEffect(() => setOpen(false), [pathname]);

  return (
    <header className="mk-nav" data-scrolled={scrolled} data-open={open}>
      <div className="mk-container">
        <nav className="mk-nav-bar" aria-label="Main">
          <Link href="/" aria-label="Tether home">
            <Logo />
          </Link>
          <div className="mk-nav-links">
            {site.nav.map((item) => (
              <Link
                key={item.href}
                href={item.href}
                aria-current={pathname === item.href ? 'page' : undefined}
              >
                {item.label}
              </Link>
            ))}
          </div>
          <div className="mk-nav-actions">
            <Link href="/login" className="mk-nav-login">
              Staff login
            </Link>
            <Link href="/contact" className="mk-btn mk-btn-primary mk-btn-sm">
              Propose your gym
            </Link>
            <button
              type="button"
              className="mk-nav-toggle"
              aria-label={open ? 'Close menu' : 'Open menu'}
              aria-expanded={open}
              onClick={() => setOpen((value) => !value)}
            >
              {open ? <X size={20} /> : <Menu size={20} />}
            </button>
          </div>
        </nav>
        <div className="mk-nav-sheet">
          {site.nav.map((item) => (
            <Link key={item.href} href={item.href}>
              {item.label}
            </Link>
          ))}
          <Link href="/login">Staff login</Link>
          <Link href="/contact" className="mk-btn mk-btn-primary">
            Propose your gym <ArrowRight size={18} />
          </Link>
        </div>
      </div>
    </header>
  );
}

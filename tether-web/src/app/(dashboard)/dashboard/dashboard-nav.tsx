'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  Bell,
  ClipboardList,
  LayoutList,
  LineChart,
  MessageSquare,
  Settings,
  Users,
} from 'lucide-react';

const navItems = [
  { href: '/dashboard', label: 'Overview', icon: LayoutList },
  { href: '/dashboard/members', label: 'Members', icon: Users },
  { href: '/dashboard/analytics', label: 'Analytics', icon: LineChart },
  { href: '/dashboard/roster', label: 'Roster', icon: ClipboardList },
  { href: '/dashboard/notices', label: 'Notices', icon: Bell },
  { href: '/dashboard/feed', label: 'Feed', icon: MessageSquare },
];

function isActive(pathname: string, href: string) {
  return pathname === href || (href !== '/dashboard' && pathname.startsWith(`${href}/`));
}

export function DashboardNav() {
  const pathname = usePathname();

  return (
    <nav className="tdash-nav" aria-label="Staff navigation">
      {navItems.map(({ href, label, icon: Icon }) => (
        <Link
          key={href}
          href={href}
          className="tdash-nav-link"
          aria-current={isActive(pathname, href) ? 'page' : undefined}
          title={label}
        >
          <Icon size={18} strokeWidth={1.75} aria-hidden />
          <span className="tdash-nav-label">{label}</span>
        </Link>
      ))}
    </nav>
  );
}

export function SettingsNavLink() {
  const pathname = usePathname();
  return (
    <Link
      href="/dashboard/settings"
      className="tdash-nav-link"
      aria-current={isActive(pathname, '/dashboard/settings') ? 'page' : undefined}
      title="Settings"
    >
      <Settings size={18} strokeWidth={1.75} aria-hidden />
      <span className="tdash-nav-label">Settings</span>
    </Link>
  );
}

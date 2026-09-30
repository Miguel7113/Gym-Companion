import Link from 'next/link';
import { Logo } from './logo';
import { site } from './site';

const columns = [
  {
    title: 'Product',
    links: [
      { href: '/features', label: 'Member app' },
      { href: '/features#portal', label: 'Staff portal' },
      { href: '/pricing', label: 'Pricing' },
    ],
  },
  {
    title: 'Gyms',
    links: [
      { href: '/contact', label: 'Propose your gym' },
      { href: '/login', label: 'Staff login' },
      { href: '/pricing#faq', label: 'FAQ' },
    ],
  },
  {
    title: 'Legal',
    links: [
      { href: '/privacy', label: 'Privacy' },
      { href: '/terms', label: 'Terms' },
      { href: `mailto:${site.email}`, label: 'Email us' },
    ],
  },
];

export function SiteFooter() {
  return (
    <footer className="mk-footer">
      <div className="mk-container">
        <div className="mk-footer-top">
          <div style={{ display: 'grid', gap: 24, alignContent: 'start' }}>
            <Logo />
            <p className="mk-footer-pitch">
              The companion app your members use every day, and the portal your staff run the gym from.
            </p>
          </div>
          {columns.map((column) => (
            <div key={column.title}>
              <h4>{column.title}</h4>
              <ul>
                {column.links.map((link) => (
                  <li key={link.href}>
                    <Link href={link.href}>{link.label}</Link>
                  </li>
                ))}
              </ul>
            </div>
          ))}
        </div>
        <div className="mk-footer-word" aria-hidden="true">
          TETHER
        </div>
        <div className="mk-footer-bottom">
          <span>
            © {new Date().getFullYear()} {site.company}. Built in {site.city}.
          </span>
          <span>Made for gyms, not individual gym-goers.</span>
        </div>
      </div>
    </footer>
  );
}

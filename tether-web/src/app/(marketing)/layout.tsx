import 'lenis/dist/lenis.css';
import './marketing.css';
import type { Metadata } from 'next';
import { SiteFooter } from '@/components/marketing/site-footer';
import { SiteNav } from '@/components/marketing/site-nav';
import { SmoothScroll } from '@/components/marketing/smooth-scroll';

export const metadata: Metadata = {
  title: {
    default: 'Tether — The companion app for your gym',
    template: '%s · Tether',
  },
  description:
    'Tether gives gyms a member app for workouts, progress and community, plus a staff portal to run the roster, notices and feed.',
};

// Runs before first paint so scroll-reveal content starts hidden instead of flashing.
const motionScript = `if(!matchMedia('(prefers-reduced-motion: reduce)').matches)document.documentElement.classList.add('mk-motion')`;

export default function MarketingLayout({ children }: { children: React.ReactNode }) {
  return (
    <>
      <script dangerouslySetInnerHTML={{ __html: motionScript }} />
      <div className="mk">
        <SmoothScroll />
        <SiteNav />
        <main>{children}</main>
        <SiteFooter />
      </div>
    </>
  );
}

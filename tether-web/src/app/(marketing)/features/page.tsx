import type { Metadata } from 'next';
import Image from 'next/image';
import Link from 'next/link';
import {
  ArrowRight,
  BadgeCheck,
  BarChart3,
  Bell,
  CalendarDays,
  Check,
  Dumbbell,
  FileSpreadsheet,
  Flag,
  Heart,
  Settings,
  Trophy,
  UserPlus,
  Users,
  WifiOff,
} from 'lucide-react';
import { FeedScreen, NoticesScreen, PhoneFrame, WorkoutScreen } from '@/components/marketing/app-screens';
import { Parallax, Reveal, SplitHeading } from '@/components/marketing/motion';
import { PortalMockup } from '@/components/marketing/portal-mockup';
import { photos } from '@/components/marketing/site';

export const metadata: Metadata = {
  title: 'Features',
  description: 'Everything in the Tether member app and staff portal.',
};

const memberFeatures = [
  { icon: Dumbbell, title: 'Workout logging', body: 'Sets, reps, weight, and rest timers, with every exercise’s history one tap away.' },
  { icon: Trophy, title: 'Personal records', body: 'PRs are detected automatically and can be shared to the gym feed in one tap.' },
  { icon: CalendarDays, title: 'Coach programmes', body: 'Weekly routines written by your coaches, ready for members to start.' },
  { icon: Heart, title: 'Gym feed', body: 'Workouts, PRs, kudos, and comments, visible only to members of your gym.' },
  { icon: Users, title: 'Training buddies', body: 'Members connect with the people they train with and follow each other’s progress.' },
  { icon: WifiOff, title: 'Works offline', body: 'Workouts keep logging without signal and sync when the phone reconnects.' },
];

const portalFeatures = [
  { icon: FileSpreadsheet, title: 'Roster import', body: 'Upload your member list as a CSV. Only people on it can join your gym.' },
  { icon: UserPlus, title: 'Approvals', body: 'Review pending members and match them to their records in one place.' },
  { icon: Bell, title: 'Notices', body: 'Post, pin, and tag announcements. Coaches can post from the app too.' },
  { icon: Flag, title: 'Moderation', body: 'Reported posts land in a queue so staff can hide or remove them fast.' },
  { icon: BarChart3, title: 'Analytics', body: 'Workouts per week, busy hours, and activity trends across your members.' },
  { icon: Settings, title: 'Gym settings', body: 'Your gym’s name, logo, colours, and timezone, managed by your team.' },
];

export default function FeaturesPage() {
  return (
    <>
      <section className="mk-page-hero mk-dark">
        <div className="mk-container">
          <Reveal immediate>
            <span className="mk-eyebrow">Features</span>
          </Reveal>
          <SplitHeading
            as="h1"
            className="mk-display"
            text={'Two products.\nOne gym.'}
            accent={['One']}
            immediate
            delay={0.1}
          />
          <Reveal immediate delay={0.5}>
            <p className="mk-lead">
              A member app that makes training visible, and a staff portal that keeps the gym running. Both share the
              same live data, so what staff change, members see straight away.
            </p>
          </Reveal>
        </div>
      </section>

      {/* Member app: three phones */}
      <section className="mk-dark" style={{ paddingBottom: 'clamp(88px, 12vw, 168px)' }}>
        <div className="mk-container">
          <Reveal
            stagger={0.12}
            style={{ display: 'flex', justifyContent: 'center', alignItems: 'flex-end', gap: 24, flexWrap: 'wrap' }}
          >
            <div style={{ transform: 'translateY(40px)' }}>
              <PhoneFrame width={270}>
                <NoticesScreen />
              </PhoneFrame>
            </div>
            <PhoneFrame width={300}>
              <WorkoutScreen />
            </PhoneFrame>
            <div style={{ transform: 'translateY(40px)' }}>
              <PhoneFrame width={270}>
                <FeedScreen />
              </PhoneFrame>
            </div>
          </Reveal>
        </div>
      </section>

      <section className="mk-section mk-light">
        <div className="mk-container">
          <div className="mk-head">
            <Reveal>
              <span className="mk-eyebrow">Member app</span>
            </Reveal>
            <SplitHeading className="mk-h2" text={'Built for the\ngym floor.'} />
            <Reveal>
              <p className="mk-lead">Fast enough to use between sets. Useful enough that members open it every session.</p>
            </Reveal>
          </div>
          <FeatureGrid items={memberFeatures} />
        </div>
      </section>

      {/* Full-bleed photo break */}
      <section style={{ position: 'relative', height: 'min(80vh, 760px)', overflow: 'hidden' }} className="mk-dark">
        <Parallax speed={18} style={{ position: 'absolute', inset: '-10% 0' }}>
          <Image src={photos.curl} alt="Member training with a barbell" fill sizes="100vw" style={{ objectFit: 'cover' }} />
        </Parallax>
        <div
          style={{
            position: 'absolute',
            inset: 0,
            background: 'linear-gradient(0deg, rgb(0 0 0 / 80%), rgb(0 0 0 / 10%) 60%)',
            display: 'flex',
            alignItems: 'flex-end',
          }}
        >
          <div className="mk-container" style={{ paddingBottom: 'clamp(40px, 6vw, 80px)' }}>
            <SplitHeading className="mk-h2" text={'Coaches see the work.\nMembers feel it.'} accent={['feel']} />
          </div>
        </div>
      </section>

      <section className="mk-section mk-white-bg" id="portal">
        <div className="mk-container">
          <div className="mk-split">
            <div style={{ display: 'grid', gap: 24 }}>
              <Reveal>
                <span className="mk-eyebrow">Staff portal</span>
              </Reveal>
              <SplitHeading className="mk-h2" text={'Your gym’s\ncontrol room.'} />
              <Reveal>
                <p className="mk-lead">
                  Owners and managers use the web portal. Coaches get lighter tools in the app, like posting notices and
                  certifying workouts.
                </p>
                <ul className="mk-checklist">
                  {['Staff-only access, separate from member accounts', 'Every action tied to your gym and nobody else’s', 'Works on any laptop or tablet browser'].map(
                    (item) => (
                      <li key={item}>
                        <Check size={20} /> {item}
                      </li>
                    ),
                  )}
                </ul>
              </Reveal>
            </div>
            <Reveal y={80}>
              <PortalMockup />
            </Reveal>
          </div>
          <div style={{ marginTop: 'clamp(64px, 8vw, 112px)' }}>
            <FeatureGrid items={portalFeatures} light />
          </div>
        </div>
      </section>

      <section className="mk-section mk-dark">
        <div className="mk-container">
          <div className="mk-split mk-split-rev">
            <Reveal className="mk-photo" style={{ minHeight: 520 }}>
              <Image src={photos.press} alt="Athlete pressing a barbell overhead" fill sizes="(max-width: 960px) 100vw, 55vw" />
              <span className="mk-eyebrow" style={{ color: 'rgb(255 255 255 / 80%)' }}>
                Coach tools
              </span>
            </Reveal>
            <div style={{ display: 'grid', gap: 24 }}>
              <SplitHeading className="mk-h2" text={'Workouts,\ncoach-certified.'} />
              <Reveal>
                <p className="mk-lead">
                  Members share finished workouts to the feed. Coaches review them from a queue in the app and certify the
                  ones they’ve seen, and the badge shows up on the post for the whole gym.
                </p>
                <ul className="mk-checklist">
                  <li>
                    <BadgeCheck size={20} /> A certify queue built into the coach app
                  </li>
                  <li>
                    <Trophy size={20} /> The coach’s name on every certified post
                  </li>
                  <li>
                    <Bell size={20} /> Coaches post notices from the same app
                  </li>
                </ul>
              </Reveal>
            </div>
          </div>
        </div>
      </section>

      <section className="mk-section mk-light" style={{ paddingTop: 0, background: 'var(--mk-black)' }}>
        <div className="mk-container">
          <Reveal className="mk-cta" y={60}>
            <h2 className="mk-h2" style={{ maxWidth: '14ch' }}>
              See Tether running in your gym.
            </h2>
            <div className="mk-cta-actions">
              <Link href="/contact" className="mk-btn mk-btn-dark">
                Propose your gym <ArrowRight size={18} />
              </Link>
              <Link href="/pricing" className="mk-btn mk-btn-outline">
                See plans
              </Link>
            </div>
          </Reveal>
        </div>
      </section>
    </>
  );
}

type Feature = { icon: React.ComponentType<{ size?: number }>; title: string; body: string };

function FeatureGrid({ items, light }: { items: Feature[]; light?: boolean }) {
  return (
    <Reveal className="mk-cards" stagger={0.08}>
      {items.map(({ icon: Icon, title, body }) => (
        <article key={title} className="mk-card" style={light ? { background: 'var(--mk-paper)', minHeight: 240 } : { minHeight: 240 }}>
          <span className="mk-card-icon">
            <Icon size={24} />
          </span>
          <h3>{title}</h3>
          <p>{body}</p>
        </article>
      ))}
    </Reveal>
  );
}

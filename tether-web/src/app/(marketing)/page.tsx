import Image from 'next/image';
import Link from 'next/link';
import {
  ArrowRight,
  BadgeCheck,
  Bell,
  Check,
  MapPin,
  ShieldCheck,
  Smartphone,
  Users,
} from 'lucide-react';
import { FeedScreen, HomeScreen, NoticesScreen, PhoneFrame, WorkoutScreen } from '@/components/marketing/app-screens';
import { Marquee } from '@/components/marketing/marquee';
import { Parallax, Reveal, ScrubText, SplitHeading } from '@/components/marketing/motion';
import { PhoneShowcase } from '@/components/marketing/phone-showcase';
import { PortalMockup } from '@/components/marketing/portal-mockup';
import { photos } from '@/components/marketing/site';

const showcaseSteps = [
  {
    title: 'Every set, logged in seconds.',
    body: 'Members follow your coaches’ programmes or build their own, log sets as they go, and watch their progress climb.',
    points: ['Programmes written by your own coaches', 'Automatic personal-record detection', 'Works on the gym floor, even on patchy Wi-Fi'],
    screen: <WorkoutScreen />,
  },
  {
    title: 'A feed that belongs to your gym.',
    body: 'PRs and finished workouts land in a feed only your members can see. Kudos, comments, and coach-certified workouts keep people coming back.',
    points: ['Private to your members, nobody else', 'Coaches certify members’ workouts', 'Staff moderation built in'],
    screen: <FeedScreen />,
  },
  {
    title: 'Notices people actually read.',
    body: 'Class changes, closures, and events go straight to the app, with pins and tags. No more announcements lost in a 200-person WhatsApp group.',
    points: ['Pinned notices stay at the top', 'Tags for classes, events, and reminders', 'Posted by coaches from their phone'],
    screen: <NoticesScreen />,
  },
  {
    title: 'Their day at a glance.',
    body: 'Streaks, weekly workouts, and who’s training right now. A home screen that makes showing up feel like progress.',
    points: ['Streaks and weekly goals', 'See how busy the gym is', 'Your gym’s latest notices up top'],
    screen: <HomeScreen />,
  },
];

export default function HomePage() {
  return (
    <>
      {/* Hero */}
      <section className="mk-hero mk-dark">
        <Parallax className="mk-hero-media" speed={14}>
          <Image src={photos.hero} alt="" fill priority sizes="100vw" />
        </Parallax>
        <div className="mk-container">
          <div className="mk-hero-grid">
            <div className="mk-hero-copy">
              <Reveal immediate delay={0.1}>
                <span className="mk-eyebrow">The gym companion platform</span>
              </Reveal>
              <SplitHeading
                as="h1"
                className="mk-display"
                style={{ marginTop: 24 }}
                text={'Your gym,\nin every member’s\npocket.'}
                accent={['pocket']}
                immediate
                delay={0.15}
              />
              <Reveal immediate delay={0.6}>
                <p className="mk-lead">
                  Tether gives your members an app for workouts, progress, and community, built around your gym.
                  Your staff get one portal to run the roster, notices, and feed.
                </p>
                <div className="mk-hero-ctas">
                  <Link href="/contact" className="mk-btn mk-btn-primary">
                    Propose your gym <ArrowRight size={18} />
                  </Link>
                  <Link href="/features" className="mk-btn mk-btn-outline">
                    See how it works
                  </Link>
                </div>
              </Reveal>
            </div>
            <Reveal immediate delay={0.5} y={80} className="mk-hero-phone">
              <PhoneFrame width={300}>
                <HomeScreen />
              </PhoneFrame>
            </Reveal>
          </div>
          <Reveal immediate delay={0.9} className="mk-hero-meta">
            <span>
              <MapPin size={16} /> Built in Nairobi, for East African gyms
            </span>
            <span>
              <Smartphone size={16} /> iOS and Android
            </span>
            <span>
              <ShieldCheck size={16} /> Members never pay extra
            </span>
          </Reveal>
        </div>
      </section>

      {/* Problem statement */}
      <section className="mk-section mk-light">
        <div className="mk-container">
          <Reveal>
            <span className="mk-eyebrow">The problem</span>
          </Reveal>
          <ScrubText
            className="mk-statement"
            text="Spreadsheets for the roster. WhatsApp for announcements. A generic app your members found on their own. None of it carries your gym’s name, and none of it keeps people coming back."
          />
          <div style={{ marginTop: 56 }}>
            <Marquee
              items={['Workout logging', 'Personal records', 'Gym feed', 'Coach programmes', 'Pinned notices', 'Roster control', 'Feed moderation', 'Member insights']}
            />
          </div>
        </div>
      </section>

      {/* Member app showcase */}
      <section className="mk-dark" style={{ paddingTop: 'clamp(88px, 12vw, 168px)' }}>
        <div className="mk-container">
          <div className="mk-head">
            <Reveal>
              <span className="mk-eyebrow">For your members</span>
            </Reveal>
            <SplitHeading className="mk-h2" text={'The app they open\nevery training day.'} />
          </div>
          <PhoneShowcase steps={showcaseSteps} />
        </div>
      </section>

      {/* Staff portal */}
      <section className="mk-section mk-white-bg" id="portal">
        <div className="mk-container">
          <div className="mk-head-row">
            <div style={{ display: 'grid', gap: 24, maxWidth: 760 }}>
              <Reveal>
                <span className="mk-eyebrow">For your staff</span>
              </Reveal>
              <SplitHeading className="mk-h2" text={'Run the whole gym\nfrom one screen.'} />
            </div>
            <Reveal>
              <p className="mk-lead" style={{ maxWidth: 420 }}>
                The staff portal is where owners and managers approve members, post notices, keep the feed clean, and
                see who’s actually training.
              </p>
            </Reveal>
          </div>
          <Reveal y={80}>
            <PortalMockup />
          </Reveal>
          <Reveal className="mk-cards" stagger={0.1} style={{ marginTop: 16 }}>
            <PortalCard icon={<Users size={24} />} title="Roster control" body="Import your member list from CSV. Only people on your roster can join, so the app stays yours." />
            <PortalCard icon={<Bell size={24} />} title="Notices and feed" body="Post announcements, pin what matters, and moderate reported posts before they become a problem." />
            <PortalCard icon={<BadgeCheck size={24} />} title="Real engagement data" body="Workouts per week, busy hours, and member activity, so you can see who’s training and who’s gone quiet." />
          </Reveal>
        </div>
      </section>

      {/* Photo bento */}
      <section className="mk-section mk-dark">
        <div className="mk-container">
          <div className="mk-head">
            <Reveal>
              <span className="mk-eyebrow">Why gyms choose Tether</span>
            </Reveal>
            <SplitHeading className="mk-h2" text={'Retention is built\non the gym floor.'} />
          </div>
          <div className="mk-bento">
            <Reveal className="mk-photo mk-span-7 mk-tall">
              <Image src={photos.squat} alt="Athlete squatting with a loaded barbell" fill sizes="(max-width: 880px) 100vw, 60vw" />
              <h3>Members who track, stay.</h3>
              <p>People who can see their progress keep showing up. Tether puts every lift and every streak in their pocket.</p>
            </Reveal>
            <Reveal className="mk-photo mk-span-5" delay={0.1}>
              <Image src={photos.coach} alt="Coach resting between sets" fill sizes="(max-width: 880px) 100vw, 40vw" />
              <h3>Your coaches, amplified.</h3>
              <p>Programmes, certified workouts, and notices reach every member, not just the ones in the room.</p>
            </Reveal>
            <Reveal className="mk-photo mk-span-5" delay={0.2}>
              <Image src={photos.ropes} alt="Athlete training with battle ropes" fill sizes="(max-width: 880px) 100vw, 40vw" />
              <h3>A reason to pick you.</h3>
              <p>An app built around your gym is a perk the gym down the road doesn’t have.</p>
            </Reveal>
          </div>
        </div>
      </section>

      {/* How it works */}
      <section className="mk-section mk-light">
        <div className="mk-container">
          <div className="mk-head">
            <Reveal>
              <span className="mk-eyebrow">How it works</span>
            </Reveal>
            <SplitHeading className="mk-h2" text={'Live in weeks,\nnot months.'} />
          </div>
          <Reveal className="mk-steps" stagger={0.12}>
            <Step n="01" title="Propose your gym" body="Tell us about your gym. We’re onboarding a small group of Nairobi gyms first, and we review every application personally." />
            <Step n="02" title="We load your roster" body="Send us your member list. We set up your gym, your staff accounts, and your coaches’ first programmes with you." />
            <Step n="03" title="Members download and train" body="Members sign in with the email or phone number you already have on file. No codes to hand out, no extra fees." />
          </Reveal>
        </div>
      </section>

      {/* CTA */}
      <section className="mk-light" style={{ paddingBottom: 'clamp(64px, 8vw, 112px)' }}>
        <div className="mk-container">
          <Reveal className="mk-cta" y={60}>
            <span className="mk-eyebrow" style={{ color: 'rgb(0 0 0 / 60%)' }}>
              Founding gyms
            </span>
            <h2 className="mk-h2" style={{ marginTop: 24, maxWidth: '12ch' }}>
              Be one of the first gyms on Tether.
            </h2>
            <p className="mk-lead">
              Founding gyms get hands-on onboarding, a direct line to the team building the product, and a say in what
              we build next.
            </p>
            <ul className="mk-checklist" style={{ marginTop: 28 }}>
              {['Personal onboarding for your staff and coaches', 'Pricing locked in while we grow'].map((item) => (
                <li key={item}>
                  <Check size={20} style={{ color: 'var(--mk-black)' }} /> {item}
                </li>
              ))}
            </ul>
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

function PortalCard({ icon, title, body }: { icon: React.ReactNode; title: string; body: string }) {
  return (
    <article className="mk-card" style={{ background: 'var(--mk-paper)' }}>
      <span className="mk-card-icon">{icon}</span>
      <h3>{title}</h3>
      <p>{body}</p>
    </article>
  );
}

function Step({ n, title, body }: { n: string; title: string; body: string }) {
  return (
    <div className="mk-step">
      <span className="mk-step-num">{n}</span>
      <h3>{title}</h3>
      <p>{body}</p>
    </div>
  );
}

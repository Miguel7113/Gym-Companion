import type { ReactNode } from 'react';
import {
  Bell,
  BadgeCheck,
  Check,
  Dumbbell,
  Flame,
  Heart,
  House,
  MessageCircle,
  MoreHorizontal,
  Pin,
  Trophy,
  User,
  Users,
} from 'lucide-react';
import { photos } from './site';

export function PhoneFrame({ children, width = 320 }: { children: ReactNode; width?: number }) {
  return (
    <div className="mk-phone" style={{ '--w': `${width}px` } as React.CSSProperties}>
      <div className="mk-phone-screen">
        <div className="mk-phone-island" />
        {children}
      </div>
    </div>
  );
}

type Tab = 'home' | 'train' | 'feed' | 'profile';

function StatusBar() {
  return (
    <div className="app-status">
      <span>9:41</span>
      <span>● ● ●</span>
    </div>
  );
}

function BottomNav({ active }: { active: Tab }) {
  const tabs: { id: Tab; label: string; icon: ReactNode }[] = [
    { id: 'home', label: 'Home', icon: <House /> },
    { id: 'train', label: 'Train', icon: <Dumbbell /> },
    { id: 'feed', label: 'Feed', icon: <Users /> },
    { id: 'profile', label: 'Profile', icon: <User /> },
  ];
  return (
    <>
      <div className="app-fade" />
      <div className="app-nav">
        {tabs.map((tab) => (
          <span key={tab.id} data-active={tab.id === active}>
            {tab.icon}
            {tab.label}
          </span>
        ))}
      </div>
    </>
  );
}

const bg = (src: string) => ({ backgroundImage: `url(${src})` });

export function HomeScreen() {
  return (
    <div className="app">
      <StatusBar />
      <div className="app-top">
        <span className="app-icon-btn">
          <User size={16} />
        </span>
        <span className="app-wordmark">TETHER</span>
        <span className="app-icon-btn">
          <Bell size={16} />
        </span>
      </div>
      <div className="app-label">Today · Iron Temple Westlands</div>
      <div className="app-tiles">
        <div className="app-tile app-tile-wide" style={bg(photos.coach)}>
          <strong>3</strong>
          <span>Workouts this week</span>
        </div>
        <div className="app-tile" style={bg(photos.barbell)}>
          <strong>12</strong>
          <span>Day streak</span>
        </div>
        <div className="app-tile" style={bg(photos.rack)}>
          <strong>48</strong>
          <span>Active today</span>
        </div>
      </div>
      <div className="app-label" style={{ marginTop: '1.1em' }}>
        Gym notices
      </div>
      <div className="app-card" style={{ display: 'grid', gap: '0.45em' }}>
        <div className="app-row">
          <span className="app-pill">
            <Pin size={10} /> Class update
          </span>
          <span className="app-muted" style={{ fontSize: '0.7em', marginLeft: 'auto' }}>
            2h ago
          </span>
        </div>
        <strong style={{ fontSize: '0.95em' }}>Thursday HIIT moves to 6:30pm</strong>
        <span className="app-muted" style={{ fontSize: '0.78em' }}>
          Coach Achieng is running a double session this week. Bring a towel.
        </span>
      </div>
      <BottomNav active="home" />
    </div>
  );
}

export function WorkoutScreen() {
  const sets = [
    { n: 1, prev: '60 × 10', kg: 62.5, reps: 10, done: true },
    { n: 2, prev: '65 × 8', kg: 67.5, reps: 8, done: true },
    { n: 3, prev: '70 × 6', kg: 72.5, reps: 6, done: true },
    { n: 4, prev: '70 × 6', kg: 72.5, reps: 5, done: false },
  ];
  return (
    <div className="app">
      <StatusBar />
      <div className="app-top">
        <div>
          <div className="app-title" style={{ fontSize: '1.5em' }}>
            Push Day
          </div>
          <span className="app-muted" style={{ fontSize: '0.78em' }}>
            Coach Otieno&apos;s Hypertrophy · Week 3
          </span>
        </div>
        <span className="app-pill">42:18</span>
      </div>
      <div className="app-stats" style={{ gridTemplateColumns: 'repeat(3, 1fr)', marginBottom: '0.8em' }}>
        <div>
          <strong>6,240 kg</strong>
          <span>Volume</span>
        </div>
        <div>
          <strong>14</strong>
          <span>Sets</span>
        </div>
        <div>
          <strong>4 / 6</strong>
          <span>Exercises</span>
        </div>
      </div>
      <div className="app-card" style={{ padding: '0.8em 0.6em' }}>
        <div className="app-row" style={{ padding: '0 0.3em 0.5em' }}>
          <span className="app-avatar" style={bg(photos.press)} />
          <div style={{ flex: 1 }}>
            <strong style={{ fontSize: '0.95em' }}>Bench Press (Barbell)</strong>
            <div className="app-muted" style={{ fontSize: '0.7em' }}>
              Rest 2:00
            </div>
          </div>
          <span className="app-pill">
            <Trophy size={10} /> PR
          </span>
        </div>
        <div className="app-set app-set-head">
          <span>SET</span>
          <span>PREV</span>
          <span>KG</span>
          <span>REPS</span>
          <span />
        </div>
        {sets.map((set) => (
          <div key={set.n} className={`app-set${set.done ? ' app-set-done' : ''}`}>
            <span>{set.n}</span>
            <span className="app-muted">{set.prev}</span>
            <strong>{set.kg}</strong>
            <strong>{set.reps}</strong>
            <span className="app-check">
              <Check size={11} strokeWidth={3} />
            </span>
          </div>
        ))}
      </div>
      <div className="app-card" style={{ marginTop: '0.6em', display: 'flex', alignItems: 'center', gap: '0.6em' }}>
        <span className="app-avatar" style={bg(photos.grip)} />
        <div style={{ flex: 1 }}>
          <strong style={{ fontSize: '0.9em' }}>Incline Dumbbell Press</strong>
          <div className="app-muted" style={{ fontSize: '0.7em' }}>
            3 sets · next up
          </div>
        </div>
      </div>
      <div className="app-btn" style={{ marginTop: '0.8em' }}>
        Finish workout
      </div>
    </div>
  );
}

export function FeedScreen() {
  return (
    <div className="app">
      <StatusBar />
      <div className="app-top">
        <span className="app-title">Feed</span>
        <span className="app-icon-btn">
          <Bell size={16} />
        </span>
      </div>
      <div className="app-card" style={{ padding: 0, overflow: 'hidden' }}>
        <div className="app-row" style={{ padding: '0.8em' }}>
          <span className="app-avatar" style={{ background: '#0a3d36', color: '#2de2c5' }}>
            WK
          </span>
          <div style={{ flex: 1 }}>
            <strong style={{ fontSize: '0.9em' }}>Wanjiru K.</strong>
            <div className="app-muted" style={{ fontSize: '0.72em' }}>
              Personal record · 12m ago
            </div>
          </div>
          <MoreHorizontal size={16} className="app-muted" />
        </div>
        <div style={{ ...bg(photos.hero), height: '9em', backgroundSize: 'cover', backgroundPosition: 'center 40%' }} />
        <div style={{ padding: '0.8em' }}>
          <strong style={{ fontSize: '1.05em' }}>Deadlift · 140 kg × 3</strong>
          <div className="app-row" style={{ marginTop: '0.45em', gap: '0.4em' }}>
            <span className="app-pill">
              <Trophy size={10} /> New PR
            </span>
            <span className="app-pill app-pill-neutral">
              <BadgeCheck size={10} /> Certified by Coach Otieno
            </span>
          </div>
          <div className="app-actions">
            <span style={{ color: '#2de2c5' }}>
              <Heart size={13} fill="currentColor" /> 24 Kudos
            </span>
            <span>
              <MessageCircle size={13} /> 6
            </span>
          </div>
        </div>
      </div>
      <div className="app-card" style={{ marginTop: '0.6em' }}>
        <div className="app-row" style={{ marginBottom: '0.6em' }}>
          <span className="app-avatar">BM</span>
          <div>
            <strong style={{ fontSize: '0.9em' }}>Brian M.</strong>
            <div className="app-muted" style={{ fontSize: '0.72em' }}>
              Completed a workout · 1h ago
            </div>
          </div>
        </div>
        <div className="app-stats">
          <div>
            <strong>58m</strong>
            <span>Time</span>
          </div>
          <div>
            <strong>18</strong>
            <span>Sets</span>
          </div>
          <div>
            <strong>5</strong>
            <span>Exercises</span>
          </div>
          <div>
            <strong>7.2t</strong>
            <span>Volume</span>
          </div>
        </div>
      </div>
      <BottomNav active="feed" />
    </div>
  );
}

export function NoticesScreen() {
  const notices = [
    {
      tag: 'Announcement',
      pinned: true,
      title: 'New squat racks arrive Monday',
      body: 'The lower floor closes 6–8am Monday while we install them.',
      time: 'Today',
    },
    {
      tag: 'Event',
      title: 'Saturday community run · Karura',
      body: '7am start at Gate C. All paces welcome.',
      time: 'Yesterday',
    },
    {
      tag: 'Reminder',
      title: 'Membership renewals due 1st',
      body: 'Pay at the front desk or via M-Pesa.',
      time: 'Mon',
    },
  ];
  return (
    <div className="app">
      <StatusBar />
      <div className="app-top">
        <span className="app-title">Notices</span>
        <span className="app-icon-btn">
          <Bell size={16} />
        </span>
      </div>
      <div style={{ display: 'grid', gap: '0.55em' }}>
        {notices.map((notice) => (
          <div key={notice.title} className="app-card" style={{ display: 'grid', gap: '0.4em' }}>
            <div className="app-row">
              <span className={notice.pinned ? 'app-pill' : 'app-pill app-pill-neutral'}>
                {notice.pinned && <Pin size={10} />} {notice.tag}
              </span>
              <span className="app-muted" style={{ fontSize: '0.7em', marginLeft: 'auto' }}>
                {notice.time}
              </span>
            </div>
            <strong style={{ fontSize: '0.95em' }}>{notice.title}</strong>
            <span className="app-muted" style={{ fontSize: '0.78em' }}>
              {notice.body}
            </span>
          </div>
        ))}
        <div className="app-card app-row" style={{ gap: '0.7em' }}>
          <span className="app-icon-btn" style={{ background: 'rgb(45 226 197 / 14%)', color: '#2de2c5' }}>
            <Flame size={15} />
          </span>
          <div>
            <strong style={{ fontSize: '0.88em' }}>Coach tip</strong>
            <div className="app-muted" style={{ fontSize: '0.74em' }}>
              Log your warm-up sets too. Your coach sees the full picture.
            </div>
          </div>
        </div>
      </div>
      <BottomNav active="home" />
    </div>
  );
}

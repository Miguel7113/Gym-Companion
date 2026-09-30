import {
  BarChart3,
  Bell,
  LayoutDashboard,
  MessageSquare,
  Settings,
  UserPlus,
  Users,
} from 'lucide-react';
import { GrowBars } from './motion';

const nav = [
  { label: 'Overview', icon: LayoutDashboard, active: true },
  { label: 'Members', icon: Users },
  { label: 'Roster', icon: UserPlus },
  { label: 'Notices', icon: Bell },
  { label: 'Feed', icon: MessageSquare },
  { label: 'Analytics', icon: BarChart3 },
  { label: 'Settings', icon: Settings },
];

const kpis = [
  { label: 'Active members', value: '284', delta: '+12 this month' },
  { label: 'Workouts this week', value: '1,126', delta: '+8.4%' },
  { label: 'Pending roster', value: '7', delta: 'Review now' },
  { label: 'Avg. visits / member', value: '3.2', delta: '+0.4' },
];

const roster = [
  { initials: 'AN', name: 'Amani Njoroge', status: 'Active', tone: 'ok' },
  { initials: 'FO', name: 'Faith Ochieng', status: 'Pending', tone: 'warn' },
  { initials: 'DK', name: 'David Kamau', status: 'Active', tone: 'ok' },
  { initials: 'LW', name: 'Lucy Wambui', status: 'Pending', tone: 'warn' },
];

export function PortalMockup() {
  return (
    <div className="mk-browser">
      <div className="mk-browser-bar">
        <i />
        <i />
        <i />
        <span className="mk-browser-url">portal.tether.app/dashboard</span>
      </div>
      <div className="portal">
        <div className="portal-rail">
          <div className="portal-brand">
            <b>I</b> Iron Temple
          </div>
          {nav.map(({ label, icon: Icon, active }) => (
            <span key={label} className="portal-link" data-active={Boolean(active)}>
              <Icon size={14} /> {label}
            </span>
          ))}
        </div>
        <div className="portal-main">
          <div className="portal-kpis">
            {kpis.map((kpi) => (
              <div key={kpi.label} className="portal-card">
                <small>{kpi.label}</small>
                <strong>{kpi.value}</strong>
                <em>{kpi.delta}</em>
              </div>
            ))}
          </div>
          <div className="portal-split">
            <div className="portal-card">
              <small>Workouts logged · last 14 days</small>
              <GrowBars values={[42, 55, 48, 62, 70, 38, 30, 58, 66, 61, 78, 84, 46, 40]} highlight={11} />
            </div>
            <div className="portal-card">
              <small>Roster approvals</small>
              <div className="portal-list">
                {roster.map((row) => (
                  <div key={row.name} className="portal-list-row">
                    <span className="portal-av">{row.initials}</span>
                    <span>{row.name}</span>
                    <span className="portal-tag" data-tone={row.tone}>
                      {row.status}
                    </span>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

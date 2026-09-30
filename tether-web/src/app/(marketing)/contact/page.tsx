import type { Metadata } from 'next';
import Image from 'next/image';
import { Clock, Mail, MapPin } from 'lucide-react';
import { Reveal, SplitHeading } from '@/components/marketing/motion';
import { photos, site } from '@/components/marketing/site';
import { LeadForm } from './lead-form';

export const metadata: Metadata = {
  title: 'Propose your gym',
  description: 'Apply to bring Tether to your gym. We review every application personally.',
};

export default function ContactPage() {
  return (
    <section className="mk-dark" style={{ padding: 'clamp(150px, 16vw, 200px) 0 clamp(88px, 10vw, 140px)' }}>
      <div className="mk-container">
        <div className="mk-split" style={{ alignItems: 'start' }}>
          <div style={{ display: 'grid', gap: 28, position: 'sticky', top: 120 }}>
            <Reveal immediate>
              <span className="mk-eyebrow">Propose your gym</span>
            </Reveal>
            <SplitHeading
              as="h1"
              className="mk-h2"
              text={'Bring Tether\nto your gym.'}
              accent={['your', 'gym.']}
              immediate
              delay={0.1}
            />
            <Reveal immediate delay={0.4}>
              <p className="mk-lead">
                We’re onboarding a small group of founding gyms in Nairobi. Tell us about yours and we’ll set up a short
                call to walk you through the app and the portal.
              </p>
              <ul className="mk-checklist" style={{ marginTop: 36 }}>
                <li>
                  <Clock size={20} /> We reply within a few working days
                </li>
                <li>
                  <MapPin size={20} /> {site.city}
                </li>
                <li>
                  <Mail size={20} /> <a href={`mailto:${site.email}`}>{site.email}</a>
                </li>
              </ul>
            </Reveal>
            <Reveal immediate delay={0.5} className="mk-photo" style={{ minHeight: 260, marginTop: 12 }}>
              <Image src={photos.rack} alt="Dumbbell rack in a gym" fill sizes="(max-width: 960px) 100vw, 45vw" />
              <p style={{ marginTop: 0, color: 'white', fontWeight: 600 }}>No member fees. No app for you to build.</p>
            </Reveal>
          </div>
          <Reveal immediate delay={0.3} y={60}>
            <LeadForm email={site.email} />
          </Reveal>
        </div>
      </div>
    </section>
  );
}

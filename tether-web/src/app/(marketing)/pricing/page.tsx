import type { Metadata } from 'next';
import Link from 'next/link';
import { ArrowRight, Check, Plus } from 'lucide-react';
import { Reveal, SplitHeading } from '@/components/marketing/motion';

export const metadata: Metadata = {
  title: 'Pricing',
  description: 'Tether plans for gyms of every size. Members never pay extra.',
};

const tiers = [
  {
    name: 'Starter',
    size: 'Up to 100',
    desc: 'For boutique studios and new gyms getting their members onto one app.',
    features: ['Member app for iOS and Android', 'Workout logging and programmes', 'Gym feed and notices', 'Staff portal with roster import', 'Email support'],
  },
  {
    name: 'Growth',
    size: '100–300',
    featured: true,
    desc: 'For established gyms that want coaches and community doing the retention work.',
    features: ['Everything in Starter', 'Coach tools and workout certification', 'Feed moderation queue', 'Engagement analytics', 'Priority onboarding'],
  },
  {
    name: 'Established',
    size: '300+',
    desc: 'For large and multi-coach gyms that need a tailored rollout.',
    features: ['Everything in Growth', 'Tailored onboarding for your staff', 'Early access to new features', 'Direct line to the Tether team', 'Custom terms'],
  },
];

const faqs = [
  {
    q: 'Do members pay anything?',
    a: 'No. Your gym pays a monthly subscription and members use Tether free as part of their membership. It’s a perk you can advertise.',
  },
  {
    q: 'Why don’t you list prices?',
    a: 'We’re onboarding a small group of founding gyms and setting pricing with them, based on member count and what each gym needs. Propose your gym and we’ll give you a clear monthly price after a short call.',
  },
  {
    q: 'How do members sign up?',
    a: 'You upload your member list. Members download the app and sign in with the email or phone number already on your roster, so only your members can join.',
  },
  {
    q: 'How long does setup take?',
    a: 'Most of the work is getting your roster in and your staff accounts created. We do that with you, and a typical gym can go live in a couple of weeks.',
  },
  {
    q: 'What happens to our data?',
    a: 'Your gym’s data belongs to your gym. We handle member data in line with Kenya’s Data Protection Act, 2019, and never sell it or show it to other gyms.',
  },
];

export default function PricingPage() {
  return (
    <>
      <section className="mk-page-hero mk-dark">
        <div className="mk-container">
          <Reveal immediate>
            <span className="mk-eyebrow">Pricing</span>
          </Reveal>
          <SplitHeading
            as="h1"
            className="mk-display"
            text={'One subscription.\nMembers ride free.'}
            accent={['free.']}
            immediate
            delay={0.1}
          />
          <Reveal immediate delay={0.5}>
            <p className="mk-lead">
              Plans scale with the number of active members at your gym. Every plan includes the member app and the staff
              portal.
            </p>
          </Reveal>
        </div>
      </section>

      <section className="mk-section mk-light">
        <div className="mk-container">
          <Reveal className="mk-tiers" stagger={0.1}>
            {tiers.map((tier) => (
              <article key={tier.name} className="mk-tier" data-featured={Boolean(tier.featured)}>
                <div className="mk-tier-name">
                  <h3>{tier.name}</h3>
                  {tier.featured && <span className="mk-tier-badge">Most gyms</span>}
                </div>
                <div className="mk-tier-size">
                  {tier.size}
                  <small>active members</small>
                </div>
                <p className="mk-tier-desc">{tier.desc}</p>
                <ul className="mk-checklist">
                  {tier.features.map((feature) => (
                    <li key={feature}>
                      <Check size={18} /> {feature}
                    </li>
                  ))}
                </ul>
                <Link href="/contact" className={`mk-btn ${tier.featured ? 'mk-btn-primary' : 'mk-btn-dark'}`}>
                  Contact us <ArrowRight size={18} />
                </Link>
              </article>
            ))}
          </Reveal>
          <Reveal>
            <p className="mk-form-note" style={{ marginTop: 24, textAlign: 'center', fontSize: 15 }}>
              Pricing is set per gym during onboarding. Founding gyms keep their price as we grow.
            </p>
          </Reveal>
        </div>
      </section>

      <section className="mk-section mk-white-bg" id="faq">
        <div className="mk-container">
          <div className="mk-split" style={{ alignItems: 'start' }}>
            <div style={{ display: 'grid', gap: 24 }}>
              <Reveal>
                <span className="mk-eyebrow">FAQ</span>
              </Reveal>
              <SplitHeading className="mk-h2" text={'Questions gym\nowners ask.'} />
              <Reveal>
                <Link href="/contact" className="mk-link-arrow">
                  Ask us something else <ArrowRight size={16} />
                </Link>
              </Reveal>
            </div>
            <Reveal className="mk-faq">
              {faqs.map((faq) => (
                <details key={faq.q}>
                  <summary>
                    {faq.q}
                    <Plus size={22} />
                  </summary>
                  <p>{faq.a}</p>
                </details>
              ))}
            </Reveal>
          </div>
        </div>
      </section>
    </>
  );
}

import type { Metadata } from 'next';
import { LegalPage } from '@/components/marketing/legal-page';
import { site } from '@/components/marketing/site';

export const metadata: Metadata = {
  title: 'Terms of service',
  description: 'The terms that apply to gyms and members using Tether.',
};

export default function TermsPage() {
  return (
    <LegalPage title="Terms of service" updated="September 2026">
      <p>
        These terms apply to the Tether member app, staff portal, and website, operated by {site.company} (“we”, “us”).
        By using Tether you agree to them.
      </p>

      <h2>Who can use Tether</h2>
      <p>
        Tether is offered to gyms, which then give access to their members. You can use the member app only if your gym
        has added you to its roster. Gym staff accounts are created by us or by an authorised administrator at the gym.
      </p>

      <h2>Gym subscriptions</h2>
      <p>
        Gyms pay a subscription agreed with us in writing. Members do not pay us anything. Details of pricing, billing,
        and notice periods for gyms are set out in each gym’s agreement with us.
      </p>

      <h2>Your account</h2>
      <p>
        Keep your sign-in details private and tell us or your gym if you think someone else has accessed your account.
        You are responsible for what happens under your account.
      </p>

      <h2>Community rules</h2>
      <ul>
        <li>Be respectful. No harassment, hate speech, or threats.</li>
        <li>Only post content you have the right to share.</li>
        <li>No spam, advertising, or impersonation.</li>
        <li>Don’t post other people’s personal information without permission.</li>
      </ul>
      <p>
        Gym staff and {site.company} can hide or remove content, and suspend accounts, that break these rules.
      </p>

      <h2>Health and safety</h2>
      <p>
        Tether is a tool for logging and sharing training. It is not medical advice. Talk to a qualified professional
        before starting a new training programme, and follow your gym’s safety guidance.
      </p>

      <h2>Your content</h2>
      <p>
        You keep ownership of what you post. You give us permission to store and display it to members of your gym so
        the service can work.
      </p>

      <h2>Availability and changes</h2>
      <p>
        Tether is in active development. We work to keep it available and reliable, but we can’t promise it will
        always be uninterrupted. We may update features and these terms, and will let gyms know about significant
        changes.
      </p>

      <h2>Liability</h2>
      <p>
        To the extent the law allows, we are not liable for indirect losses arising from use of Tether. Nothing in these
        terms limits rights you have under Kenyan consumer law.
      </p>

      <h2>Governing law</h2>
      <p>These terms are governed by the laws of Kenya.</p>

      <h2>Contact</h2>
      <p>
        Questions about these terms can go to <a href={`mailto:${site.email}`}>{site.email}</a>.
      </p>
    </LegalPage>
  );
}

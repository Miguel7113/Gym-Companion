import type { Metadata } from 'next';
import { LegalPage } from '@/components/marketing/legal-page';
import { site } from '@/components/marketing/site';

export const metadata: Metadata = {
  title: 'Privacy policy',
  description: 'How Tether collects, uses, and protects gym and member data.',
};

export default function PrivacyPage() {
  return (
    <LegalPage title="Privacy policy" updated="September 2026">
      <p>
        Tether is built and operated by {site.company}, based in {site.city}. This policy explains what data we collect
        through the Tether member app, the staff portal, and this website, and how we handle it. We process personal
        data in line with Kenya’s Data Protection Act, 2019.
      </p>

      <h2>Who is responsible for your data</h2>
      <p>
        When a gym uses Tether, the gym decides whose data is on its roster and why. For that roster data, the gym is
        the data controller and {site.company} processes it on the gym’s behalf. For data you send us through this
        website, such as a “Propose your gym” application, {site.company} is the controller.
      </p>

      <h2>What we collect</h2>
      <ul>
        <li>
          <strong>Roster data</strong> supplied by your gym, such as name, email address, phone number, and membership
          status.
        </li>
        <li>
          <strong>Account data</strong> you provide when signing in, such as your display name and profile photo.
        </li>
        <li>
          <strong>Training data</strong> you log, including workouts, sets, weights, personal records, and routines.
        </li>
        <li>
          <strong>Community content</strong> you post to your gym’s feed, including comments, kudos, and photos.
        </li>
        <li>
          <strong>Website enquiries</strong>: the details you enter in our contact form.
        </li>
        <li>
          <strong>Technical data</strong> needed to run the service, such as device type and error logs.
        </li>
      </ul>

      <h2>How we use it</h2>
      <ul>
        <li>To let you sign in and confirm you are a member of your gym.</li>
        <li>To show your training history and progress back to you.</li>
        <li>To share the content you choose to post with members of your own gym.</li>
        <li>To give gym staff the roster, moderation, and engagement tools they need to run the gym.</li>
        <li>To respond to enquiries from gyms interested in Tether.</li>
      </ul>
      <p>We do not sell personal data, and we do not show one gym’s data to another gym.</p>

      <h2>Who can see your data</h2>
      <p>
        Feed posts are visible only to members and staff of your gym. Gym staff can see roster details and aggregate
        activity for their own gym. We use a small number of service providers to host and run Tether, including
        Supabase for database and authentication and Google Cloud for our servers, and they process data only on our
        instructions.
      </p>

      <h2>How long we keep it</h2>
      <p>
        We keep account and training data while your gym uses Tether and you remain on its roster. If your gym removes
        you, or stops using Tether, we delete or anonymise your data within a reasonable period unless the law requires
        us to keep it.
      </p>

      <h2>Your rights</h2>
      <p>
        You can ask to access, correct, or delete your personal data, or object to how we process it. Contact your gym,
        or email us at <a href={`mailto:${site.email}`}>{site.email}</a>, and we will respond within the time the law
        requires. You can also complain to the Office of the Data Protection Commissioner.
      </p>

      <h2>Contact</h2>
      <p>
        Questions about this policy can go to <a href={`mailto:${site.email}`}>{site.email}</a>.
      </p>
    </LegalPage>
  );
}

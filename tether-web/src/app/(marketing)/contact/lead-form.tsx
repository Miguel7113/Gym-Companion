'use client';

import { useActionState } from 'react';
import { useFormStatus } from 'react-dom';
import { ArrowRight, Check } from 'lucide-react';
import { submitLead, type LeadFormState } from './actions';

const bands = [
  { value: 'UNDER_100', label: 'Under 100' },
  { value: '100_300', label: '100–300' },
  { value: 'OVER_300', label: '300+' },
];

function SubmitButton() {
  const { pending } = useFormStatus();
  return (
    <button type="submit" className="mk-btn mk-btn-dark" disabled={pending} style={{ justifySelf: 'start' }}>
      {pending ? 'Sending…' : 'Send application'} {!pending && <ArrowRight size={18} />}
    </button>
  );
}

export function LeadForm({ email }: { email: string }) {
  const [state, action] = useActionState<LeadFormState, FormData>(submitLead, { status: 'idle' });

  if (state.status === 'success') {
    return (
      <div className="mk-form-success" role="status">
        <span className="mk-form-success-icon">
          <Check size={30} strokeWidth={2.5} />
        </span>
        <h2 className="mk-h3">Application received.</h2>
        <p className="mk-lead">
          Thanks for proposing your gym. We review every application personally and will be in touch within a few
          working days.
        </p>
      </div>
    );
  }

  return (
    <form action={action} className="mk-form" noValidate>
      <div className="mk-form-row">
        <div className="mk-field">
          <label htmlFor="gymName">Gym name</label>
          <input id="gymName" name="gymName" className="mk-input" required maxLength={120} autoComplete="organization" />
        </div>
        <div className="mk-field">
          <label htmlFor="contactName">Your name</label>
          <input id="contactName" name="contactName" className="mk-input" required maxLength={120} autoComplete="name" />
        </div>
      </div>
      <div className="mk-form-row">
        <div className="mk-field">
          <label htmlFor="email">Work email</label>
          <input id="email" name="email" type="email" className="mk-input" required maxLength={200} autoComplete="email" />
        </div>
        <div className="mk-field">
          <label htmlFor="phone">
            Phone <span>(optional)</span>
          </label>
          <input id="phone" name="phone" type="tel" className="mk-input" maxLength={40} autoComplete="tel" placeholder="+254" />
        </div>
      </div>
      <div className="mk-field">
        <label htmlFor="city">
          City or area <span>(optional)</span>
        </label>
        <input id="city" name="city" className="mk-input" maxLength={80} placeholder="e.g. Westlands, Nairobi" />
      </div>
      <fieldset className="mk-field" style={{ border: 0, padding: 0, margin: 0 }}>
        <legend style={{ fontSize: 14, fontWeight: 600, marginBottom: 8 }}>Active members</legend>
        <div className="mk-chips">
          {bands.map((band) => (
            <label key={band.value} className="mk-chip">
              <input type="radio" name="memberCount" value={band.value} />
              <span>{band.label}</span>
            </label>
          ))}
        </div>
      </fieldset>
      <div className="mk-field">
        <label htmlFor="message">
          Anything we should know? <span>(optional)</span>
        </label>
        <textarea
          id="message"
          name="message"
          className="mk-input"
          maxLength={2000}
          placeholder="How you run things today, what you’d want from an app, timelines…"
        />
      </div>
      <div className="mk-hp" aria-hidden="true">
        <label htmlFor="website">Website</label>
        <input id="website" name="website" tabIndex={-1} autoComplete="off" />
      </div>
      {state.status === 'error' && (
        <div className="mk-form-error" role="alert">
          {state.message}
        </div>
      )}
      <SubmitButton />
      <p className="mk-form-note">
        We only use these details to contact you about Tether. Prefer email? <a href={`mailto:${email}`}>{email}</a>
      </p>
    </form>
  );
}

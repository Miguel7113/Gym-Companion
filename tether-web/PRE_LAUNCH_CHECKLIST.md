# Tether Web - Pre-Launch Checklist

**Status:** 0 of 9 completed  
**Last Updated:** October 9, 2026

---

## Overview

This checklist ensures the Tether marketing website is optimized for conversions, trust, and user experience before launch. Each section includes specific action items and acceptance criteria.

---

## ✅ Checklist Items

### 1. Conversion: Above-the-Fold CTA

**Status:** ❌ Not Started  
**Priority:** High  
**Owner:** TBD

#### Requirements
- [ ] Add prominent early-access signup form above the fold
- [ ] Include "Book a Demo" CTA button
- [ ] Ensure CTA stands out visually (contrasting colors, clear hierarchy)
- [ ] Test CTA visibility on different screen sizes
- [ ] A/B test different CTA copy variations

#### Acceptance Criteria
- Primary CTA visible without scrolling on desktop and mobile
- Form captures: email, name, organization type (gym owner/member)
- Clear value proposition accompanying the CTA
- CTA conversion tracked in analytics

#### Resources
- Design mockups: `/Design Reference/`
- Analytics tracking: Setup required

---

### 2. Conversion: Separate User Journeys

**Status:** ❌ Not Started  
**Priority:** High  
**Owner:** TBD

#### Requirements
- [ ] Create distinct landing paths for gym owners vs. gym members
- [ ] Implement path selection mechanism (buttons, dropdown, or separate URLs)
- [ ] Customize messaging for each audience segment
- [ ] Design separate feature highlights for each journey
- [ ] Create targeted CTAs for each user type

#### Acceptance Criteria
- Clear differentiation between gym owner and member benefits
- Separate landing pages or dynamic content sections
- Tailored feature lists for each audience
- Unique conversion funnels tracked separately

#### Implementation Notes
```
Suggested routes:
- /for-gyms (gym owners)
- /for-members (gym members)
- Homepage with clear journey selector
```

---

### 3. Product: Real App Screenshots & Video

**Status:** ❌ Not Started  
**Priority:** High  
**Owner:** TBD

#### Requirements
- [ ] Capture high-quality screenshots from actual Tether app
- [ ] Create 30-60 second demo video of real interface
- [ ] Show key features: workout tracking, social feed, nutrition
- [ ] Optimize images for web (WebP format, compressed)
- [ ] Add descriptive alt text for accessibility
- [ ] Include captions or annotations on screenshots

#### Acceptance Criteria
- Minimum 5 screenshots showing core features
- Video hosted on optimized platform (YouTube, Vimeo, or self-hosted)
- All images < 200KB each
- Video showcases actual app functionality (not mockups)
- Screenshots show both mobile and tablet views

#### Screenshots Needed
- [ ] Home/Social feed
- [ ] Workout tracking interface
- [ ] Exercise library
- [ ] Nutrition tracking
- [ ] Progress analytics
- [ ] Gym check-in/QR code

---

### 4. Product: Specific Benefits Communication

**Status:** ❌ Not Started  
**Priority:** Medium  
**Owner:** TBD

#### Requirements
- [ ] List concrete features for members (e.g., "Track 500+ exercises with video guides")
- [ ] List concrete features for staff (e.g., "Manage class schedules in 3 clicks")
- [ ] Replace vague claims with measurable benefits
- [ ] Use action-oriented language
- [ ] Include use cases and scenarios

#### Acceptance Criteria
- Each feature includes a specific, quantifiable benefit
- Benefits section for both gym owners and members
- Minimum 6 specific benefits per audience
- Benefits supported by screenshots or icons

#### Example Format
```
✅ Good: "Track every rep with our library of 500+ exercises"
❌ Avoid: "Great exercise tracking"

✅ Good: "Reduce check-in time from 2 minutes to 10 seconds with QR codes"
❌ Avoid: "Fast check-ins"
```

---

### 5. Trust: Social Proof & Testimonials

**Status:** ❌ Not Started  
**Priority:** Medium  
**Owner:** TBD

#### Requirements
- [ ] Obtain written permission from pilot gyms for logo usage
- [ ] Collect testimonials with names, titles, and gym names
- [ ] Take professional photos of testimonial providers (with consent)
- [ ] Display pilot gym logos in "Trusted By" section
- [ ] Include specific quotes about results/improvements

#### Acceptance Criteria
- Minimum 3 verified testimonials with full attribution
- 3-5 pilot gym logos (with signed permission)
- Testimonials include specific outcomes or metrics
- All permissions documented and filed

#### Legal Requirements
- [ ] Logo usage agreements signed
- [ ] Photo release forms obtained
- [ ] Testimonial consent documented

#### Testimonial Template
```
"[Specific outcome/benefit]"
— [Name], [Title] at [Gym Name]
```

---

### 6. Mobile: Responsive Design Testing

**Status:** ❌ Not Started  
**Priority:** High  
**Owner:** TBD

#### Requirements
- [ ] Test on iPhone (Safari & Chrome)
- [ ] Test on Android devices (Chrome & Samsung Browser)
- [ ] Test on tablet (portrait and landscape)
- [ ] Verify all CTAs are tappable (min 44x44px)
- [ ] Check hamburger menu functionality
- [ ] Ensure forms are mobile-friendly
- [ ] Test video playback on mobile

#### Test Devices
- [ ] iPhone 12/13/14 (iOS Safari)
- [ ] Samsung Galaxy S21/S22 (Chrome)
- [ ] iPad/iPad Pro
- [ ] Small screen (320px width - iPhone SE)

#### Acceptance Criteria
- All sections readable without horizontal scroll
- Forms functional with mobile keyboards
- No overlapping elements
- Touch targets properly sized
- Navigation accessible and functional

#### Testing Tools
- Chrome DevTools responsive mode
- BrowserStack or similar cross-browser testing
- Real device testing

---

### 7. Performance: Technical Optimization

**Status:** ❌ Not Started  
**Priority:** High  
**Owner:** TBD

#### Requirements
- [ ] Mobile page load time < 3 seconds on 4G
- [ ] Images optimized (WebP, lazy loading)
- [ ] Lighthouse score > 90 (mobile & desktop)
- [ ] WCAG 2.1 AA accessibility compliance
- [ ] All links functional (no 404s)
- [ ] SSL certificate installed and verified

#### Performance Targets
| Metric | Target | Tool |
|--------|--------|------|
| First Contentful Paint | < 1.5s | Lighthouse |
| Largest Contentful Paint | < 2.5s | Lighthouse |
| Time to Interactive | < 3.5s | Lighthouse |
| Cumulative Layout Shift | < 0.1 | Lighthouse |
| Total Page Size | < 2MB | Network tab |

#### Accessibility Checklist
- [ ] All images have alt text
- [ ] Proper heading hierarchy (h1, h2, h3)
- [ ] Sufficient color contrast (4.5:1 minimum)
- [ ] Keyboard navigation functional
- [ ] Form labels properly associated
- [ ] ARIA labels where needed
- [ ] Focus indicators visible

#### Testing Tools
- [ ] Google Lighthouse
- [ ] WebPageTest
- [ ] WAVE accessibility checker
- [ ] W3C Link Checker

---

### 8. Measurement: Analytics & Tracking

**Status:** ❌ Not Started  
**Priority:** High  
**Owner:** TBD

#### Requirements
- [ ] Install Google Analytics 4 (or alternative)
- [ ] Set up conversion tracking for signups
- [ ] Track demo request submissions
- [ ] Implement event tracking for all CTAs
- [ ] Track traffic sources (organic, paid, referral, social)
- [ ] Set up goal funnels
- [ ] Create analytics dashboard

#### Events to Track
- [ ] Page views (all pages)
- [ ] CTA clicks (signup, demo, learn more)
- [ ] Form submissions (success & errors)
- [ ] Video plays and completion rate
- [ ] Scroll depth
- [ ] Time on page
- [ ] User journey path selection (gym owner vs member)

#### Analytics Implementation
```javascript
// Example event tracking
trackEvent('cta_click', {
  location: 'hero',
  type: 'signup',
  user_type: 'gym_owner'
});
```

#### KPIs to Monitor
- Conversion rate (visitors → signups)
- Demo request rate
- Bounce rate per page
- Average time on site
- Traffic source breakdown
- Mobile vs desktop conversion rates

---

### 9. Launch: Final Verification

**Status:** ❌ Not Started  
**Priority:** Critical  
**Owner:** TBD

#### Requirements
- [ ] Verify launch date displayed is correct
- [ ] Confirm pricing information is accurate
- [ ] Check app availability status (iOS/Android)
- [ ] Ensure all CTAs align with actual product status
- [ ] Update "Coming Soon" vs "Available Now" messaging
- [ ] Verify email notifications are working
- [ ] Test form submissions end-to-end
- [ ] Prepare launch announcement content

#### Pre-Launch Verification Matrix
| Item | Actual Status | Website Reflects | ✓ |
|------|---------------|------------------|---|
| iOS App | [Status] | [Yes/No] | [ ] |
| Android App | [Status] | [Yes/No] | [ ] |
| Pricing | [Amount] | [Yes/No] | [ ] |
| Beta Access | [Open/Closed] | [Yes/No] | [ ] |
| Demo Booking | [Available] | [Yes/No] | [ ] |
| Support Email | [Active] | [Yes/No] | [ ] |

#### Launch Day Checklist
- [ ] Remove "under construction" notices
- [ ] Enable all forms and CTAs
- [ ] Monitor analytics in real-time
- [ ] Prepare social media announcements
- [ ] Alert support team
- [ ] Monitor error logs
- [ ] Have rollback plan ready

---

## Progress Tracking

### Sprint 1 (Week 1-2)
- [ ] Items 1, 2, 3

### Sprint 2 (Week 3-4)
- [ ] Items 4, 5, 6

### Sprint 3 (Week 5-6)
- [ ] Items 7, 8, 9

---

## Resources

### Design Assets
- Design references: `/Design Reference/`
- Brand guidelines: TBD
- Image assets: `/tether-web/public/images/`

### Development
- Repository: `tether-web/`
- Staging URL: TBD
- Production URL: TBD

### Contacts
- Product Owner: TBD
- Design Lead: TBD
- Developer: TBD
- Marketing: TBD

---

## Notes

- Keep this document updated as items are completed
- Mark completion date when each item is finished
- Link to relevant PRs or commits for traceability
- Schedule regular reviews to ensure progress

---

**Next Review Date:** [Set date]  
**Launch Target:** [Set date]

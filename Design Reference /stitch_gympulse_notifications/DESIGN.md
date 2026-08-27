---
name: Pulse
colors:
  surface: '#121317'
  surface-dim: '#121317'
  surface-bright: '#38393d'
  surface-container-lowest: '#0d0e12'
  surface-container-low: '#1a1b1f'
  surface-container: '#1e1f23'
  surface-container-high: '#292a2e'
  surface-container-highest: '#343539'
  on-surface: '#e3e2e7'
  on-surface-variant: '#c4c9ac'
  inverse-surface: '#e3e2e7'
  inverse-on-surface: '#2f3034'
  outline: '#8e9379'
  outline-variant: '#444933'
  surface-tint: '#abd600'
  primary: '#ffffff'
  on-primary: '#283500'
  primary-container: '#c3f400'
  on-primary-container: '#556d00'
  inverse-primary: '#506600'
  secondary: '#c8c6c5'
  on-secondary: '#313030'
  secondary-container: '#4a4949'
  on-secondary-container: '#bab8b7'
  tertiary: '#ffffff'
  on-tertiary: '#313030'
  tertiary-container: '#e5e2e1'
  on-tertiary-container: '#656464'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#c3f400'
  primary-fixed-dim: '#abd600'
  on-primary-fixed: '#161e00'
  on-primary-fixed-variant: '#3c4d00'
  secondary-fixed: '#e5e2e1'
  secondary-fixed-dim: '#c8c6c5'
  on-secondary-fixed: '#1c1b1b'
  on-secondary-fixed-variant: '#474646'
  tertiary-fixed: '#e5e2e1'
  tertiary-fixed-dim: '#c8c6c5'
  on-tertiary-fixed: '#1c1b1b'
  on-tertiary-fixed-variant: '#474746'
  background: '#121317'
  on-background: '#e3e2e7'
  surface-variant: '#343539'
typography:
  display-lg:
    fontFamily: Oswald
    fontSize: 48px
    fontWeight: '700'
    lineHeight: 56px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Oswald
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: 0.01em
  headline-lg-mobile:
    fontFamily: Oswald
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 34px
  headline-md:
    fontFamily: Oswald
    fontSize: 24px
    fontWeight: '500'
    lineHeight: 32px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '400'
    lineHeight: 28px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  label-caps:
    fontFamily: JetBrains Mono
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
    letterSpacing: 0.1em
  stat-lg:
    fontFamily: Oswald
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  unit: 8px
  container-margin: 20px
  gutter: 16px
  stack-sm: 12px
  stack-md: 24px
  stack-lg: 40px
---

## Brand & Style
The design system is engineered for elite performance, blending the raw intensity of a high-end gym with the sleek, interconnected feel of a modern social platform. It evokes an emotional response of "controlled adrenaline"—focused, energetic, and premium. 

The aesthetic is **Dark-Mode Glassmorphism**. It utilizes deep charcoal foundations layered with translucent "frosted" surfaces that suggest depth and sophistication. To emphasize the "Pulse" identity, the system incorporates subtle neon glows and high-energy accents that mimic the lighting of boutique fitness studios. Large-scale, high-contrast fitness photography serves as a secondary visual pillar, providing texture and human aspiration to the interface.

## Colors
This design system operates on a high-contrast dark palette. **Electric Lime (#CCFF00)** is the sole driver of action and attention, reserved for primary CTAs, progress indicators, and active states. 

The background hierarchy uses **Deep Slate (#121212)** for the lowest level (base), while **#1A1A1A** is used for elevated containers. Surface colors should never exceed 20% luminosity to maintain the "blackout" gym aesthetic. For data visualization or secondary status, use desaturated variations of the primary lime to avoid visual fatigue while maintaining brand consistency.

## Typography
The typography strategy prioritizes "Performance Readability." Headlines use **Oswald** in uppercase to mirror the industrial, bold look of gym equipment and athletic apparel. For body copy, **Inter** provides a neutral, highly legible contrast that ensures workout instructions and social feeds remain effortless to read.

A third typeface, **JetBrains Mono**, is used sparingly for technical labels, timestamps, and "metric" data (e.g., heart rate, sets, reps) to give the UI a precise, data-driven feel. Use the `stat-lg` style for personal records and primary metrics to create visual excitement.

## Layout & Spacing
The layout follows a 12-column grid for desktop and a 4-column grid for mobile, using a strict 8px base unit. To maintain the "social" feel, the system uses generous vertical rhythm (`stack-lg`) between content sections to let the photography breathe.

Card layouts should utilize "bleeding" edges for photography on mobile to maximize immersion. Horizontal scrolling "chips" and lists are preferred for workout categories and social friends-lists to keep the UI compact and mobile-first. Safe areas must be strictly respected, especially around the bottom navigation which should appear "floated" using glassmorphic properties.

## Elevation & Depth
Elevation is achieved through **Tonal Layering** and **Glassmorphism** rather than traditional drop shadows. 

1. **Base:** The primary background (#121212).
2. **Glass Layer:** 60% opacity of the surface color with a 12px-20px backdrop blur and a 1px inner border (white at 10% opacity) to catch the light.
3. **Active Glow:** Elements that are interactive or "running" (like an active timer) emit a subtle **#CCFF00** outer glow with a 20px blur at 15% opacity.

Avoid solid shadows; instead, use slightly lighter surface fills to indicate a component is closer to the user.

## Shapes
The shape language is "Generously Rounded." While the typography is sharp and condensed, the UI elements use **16px (rounded-lg)** as the standard radius to provide a modern, friendly touch to an otherwise intense aesthetic. 

Small interactive elements like chips use a full **Pill-shape**, while primary cards and modals use the standard 16px. Buttons should be slightly more aggressive with a 12px radius to bridge the gap between the sharp headlines and the soft containers.

## Components
- **Primary Buttons:** Solid Electric Lime (#CCFF00) with black uppercase Oswald text. No shadows; use a slight "scale-down" transform on tap.
- **Glass Cards:** Semi-transparent containers for social posts and workout stats. Use a 1px stroke at 10% white to define the edges against the dark background.
- **Metric Chips:** Small pill-shaped containers with JetBrains Mono text for "BPM," "KG," or "MINS."
- **Input Fields:** Bottom-border only or ghost-style with 5% white fill. The active state should change the bottom border to Electric Lime.
- **Progress Rings:** Use Electric Lime with a subtle outer glow to visualize workout completion.
- **Social Feed Items:** Large-scale imagery with text overlays using a gradient scrim (bottom-to-top) to ensure Oswald headlines remain legible over busy gym photos.
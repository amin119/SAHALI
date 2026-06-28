---
name: Sahali Civic Dashboard
colors:
  surface: '#FFFFFF'
  surface-dim: '#d8dadf'
  surface-bright: '#f7f9fe'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f1f4f9'
  surface-container: '#eceef3'
  surface-container-high: '#e6e8ed'
  surface-container-highest: '#e0e2e7'
  on-surface: '#181c20'
  on-surface-variant: '#434655'
  inverse-surface: '#2d3135'
  inverse-on-surface: '#eff1f6'
  outline: '#747686'
  outline-variant: '#c4c5d7'
  surface-tint: '#1f51da'
  primary: '#0038af'
  on-primary: '#ffffff'
  primary-container: '#1b4fd8'
  on-primary-container: '#cbd4ff'
  inverse-primary: '#b6c4ff'
  secondary: '#565e74'
  on-secondary: '#ffffff'
  secondary-container: '#dae2fd'
  on-secondary-container: '#5c647a'
  tertiary: '#3b4559'
  on-tertiary: '#ffffff'
  tertiary-container: '#525d71'
  on-tertiary-container: '#cbd6ee'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b6c4ff'
  on-primary-fixed: '#001550'
  on-primary-fixed-variant: '#003ab3'
  secondary-fixed: '#dae2fd'
  secondary-fixed-dim: '#bec6e0'
  on-secondary-fixed: '#131b2e'
  on-secondary-fixed-variant: '#3f465c'
  tertiary-fixed: '#d8e3fb'
  tertiary-fixed-dim: '#bcc7de'
  on-tertiary-fixed: '#111c2d'
  on-tertiary-fixed-variant: '#3c475a'
  background: '#f7f9fe'
  on-background: '#181c20'
  surface-variant: '#e0e2e7'
  border: '#E2E8F0'
  text-primary: '#0F172A'
  text-secondary: '#64748B'
  text-muted: '#94A3B8'
  status-submitted: '#6366F1'
  status-received: '#0EA5E9'
  status-review: '#F59E0B'
  status-scheduled: '#8B5CF6'
  status-progress: '#F97316'
  status-resolved: '#22C55E'
  status-closed: '#64748B'
  status-rejected: '#EF4444'
  priority-critical: '#EF4444'
  priority-high: '#F97316'
  priority-medium: '#F59E0B'
  priority-low: '#22C55E'
typography:
  display-stat:
    fontFamily: Inter
    fontSize: 36px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.02em
  headline-lg:
    fontFamily: Inter
    fontSize: 28px
    fontWeight: '700'
    lineHeight: 36px
  headline-md:
    fontFamily: Inter
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 28px
  headline-sm:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '600'
    lineHeight: 24px
  body-lg:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 26px
  body-md:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 22px
  label-md:
    fontFamily: Inter
    fontSize: 13px
    fontWeight: '500'
    lineHeight: 18px
    letterSpacing: 0.05em
  label-sm:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
  code-id:
    fontFamily: JetBrains Mono
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 16px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  sidebar_width: 260px
  navbar_height: 64px
  container_padding: 32px
  gutter: 24px
  stack-sm: 8px
  stack-md: 16px
  stack-lg: 24px
---

## Brand & Style

The design system is engineered for the "Sahali" municipal administration platform, serving as a high-trust, authoritative "civic control room" for Tunisian city officials. The brand personality is professional, efficient, and transparent, designed to handle high data density while remaining approachable for daily governance.

The visual style is **Corporate / Modern**, leaning into a structured, systematic aesthetic that prioritizes clarity and information hierarchy. It utilizes a sophisticated "Control Room" approach: heavy on status indicators, clear data visualizations, and a rigid grid that reflects the stability and order of municipal administration.

## Colors

The color palette is rooted in trust-inducing blues and navies, representing the stability of a government institution. 

- **Primary Blue** is used for the "Sahali" wordmark, primary actions, and active navigation states.
- **Surface & Background** colors create a "layered" effect, with a cool-tinted background (`#F4F6FB`) providing contrast for white cards.
- **Functional Mapping**: A rigorous color system is applied to statuses and priorities. These must be used consistently across the dashboard to allow administrators to scan large datasets (e.g., citizen requests in La Marsa or Ariana) and immediately identify items requiring urgent attention.

## Typography

This design system uses **Inter** as the primary typeface for its exceptional legibility in UI applications. To reinforce the "Control Room" feel, we utilize a tiered weight system:
- **Bold (700)** for high-level statistics and primary page titles.
- **SemiBold (600)** for section headers and modal titles.
- **Medium (500)** for labels, navigation items, and table headers.
- **Regular (400)** for long-form body text and descriptions.

**Monospace (JetBrains Mono)** is used specifically for technical data such as Reference IDs, Parcel Numbers, or Coordinates to ensure zero character ambiguity and perfect vertical alignment in dense tables.

## Layout & Spacing

The layout follows a **Fixed-Fluid Hybrid** model optimized for desktop administration:
- **Navigation**: A fixed 260px left-hand sidebar contains the primary city-management modules.
- **Control Bar**: A 64px top navbar provides global search, notifications, and jurisdiction switching (e.g., switching between Ariana and La Marsa).
- **Content Area**: A fluid main panel with generous 32px internal padding to ensure high-density data doesn't feel claustrophobic.

Grid structures within the content area should utilize a 12-column system for dashboard widgets, allowing for flexible layouts like a 3nd-1st-1st (stat cards) or a 2/3rd-1/3rd (table and detail view) split.

## Elevation & Depth

To maintain a professional and "flat" institutional feel, this design system uses **Tonal Layering** combined with high-precision shadows rather than heavy gradients.

- **Level 0 (Background)**: `#F4F6FB` - The base canvas.
- **Level 1 (Cards/Surface)**: `#FFFFFF` - White surfaces with a dual-shadow approach: a tight 1px shadow for edge definition and a soft 16px blur to provide a sense of "lift" without looking dated.
- **Level 2 (Modals/Popovers)**: White surfaces with a more pronounced shadow (0 10px 25px rgba(15,23,42,0.12)) to focus the administrator's attention on the task at hand.

Borders (`#E2E8F0`) are used as the primary separator for internal card elements and table rows to maintain a crisp, blueprint-like structure.

## Shapes

The shape language strikes a balance between modern friendliness and professional rigidity. 

- **Primary Containers (Cards)**: Use a 12px (`rounded-lg`) radius to soften the high data density.
- **Interactive Elements (Buttons/Inputs)**: Use an 8px radius. This slightly sharper corner communicates precision and efficiency compared to the softer container corners.
- **Status Pills**: Use full "pill" rounding (999px) to clearly distinguish status indicators from clickable buttons or input fields.

## Components

### Buttons
- **Primary**: Solid Primary Blue with white text. 8px radius.
- **Secondary**: Surface White with `#E2E8F0` border and Navy text.
- **Destructive**: Solid Red (`#EF4444`) for critical actions like "Reject Permit".

### Input Fields
- Use `#FFFFFF` backgrounds with 1px `#E2E8F0` borders. 
- Focus states should use a 2px outer glow in Primary Blue.
- Labels are positioned above the field in `label-md` style using `#64748B`.

### Status Chips
- Small, pill-shaped indicators with a subtle background (10% opacity of the status color) and a bold version of the status color for the text and a 2px leading dot.

### Data Tables
- Row height: 52px.
- Headers: `label-md` with `#64748B` text and a solid bottom border.
- Alternating row highlights or hover states are not required; use clean borders for separation to maintain a "document" feel.

### Dashboard Widgets (Cards)
- Always include a title header in `headline-sm`.
- Use the standard 12px radius and Level 1 shadow.
- Footer actions (e.g., "View All") should be right-aligned in `label-sm` Primary Blue.
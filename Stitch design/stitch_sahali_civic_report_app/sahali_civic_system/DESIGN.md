---
name: Sahali Civic System
colors:
  surface: '#faf8ff'
  surface-dim: '#d9d9e4'
  surface-bright: '#faf8ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f3f2fe'
  surface-container: '#ededf8'
  surface-container-high: '#e8e7f3'
  surface-container-highest: '#e2e1ed'
  on-surface: '#191b23'
  on-surface-variant: '#434655'
  inverse-surface: '#2e3039'
  inverse-on-surface: '#f0f0fb'
  outline: '#747686'
  outline-variant: '#c4c5d7'
  surface-tint: '#1f51da'
  primary: '#0038af'
  on-primary: '#ffffff'
  primary-container: '#1b4fd8'
  on-primary-container: '#cbd4ff'
  inverse-primary: '#b6c4ff'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d0e1fb'
  on-secondary-container: '#54647a'
  tertiary: '#7e2700'
  on-tertiary: '#ffffff'
  tertiary-container: '#a63600'
  on-tertiary-container: '#ffc9b7'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#dce1ff'
  primary-fixed-dim: '#b6c4ff'
  on-primary-fixed: '#001550'
  on-primary-fixed-variant: '#003ab3'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#ffdbcf'
  tertiary-fixed-dim: '#ffb59b'
  on-tertiary-fixed: '#380d00'
  on-tertiary-fixed-variant: '#812800'
  background: '#faf8ff'
  on-background: '#191b23'
  surface-variant: '#e2e1ed'
typography:
  display-hero:
    fontFamily: Nunito Sans
    fontSize: 34px
    fontWeight: '800'
    lineHeight: 42px
  display-hero-arabic:
    fontFamily: Cairo
    fontSize: 32px
    fontWeight: '800'
    lineHeight: 58px
  section-title:
    fontFamily: Nunito Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
  section-title-arabic:
    fontFamily: Cairo
    fontSize: 20px
    fontWeight: '700'
    lineHeight: 36px
  body-lg:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '500'
    lineHeight: 26px
  body-md:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-md-arabic:
    fontFamily: Cairo
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 28.8px
  label-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: 0.02em
  caption:
    fontFamily: Inter
    fontSize: 12px
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
  base: 8px
  xs: 4px
  sm: 12px
  md: 16px
  lg: 24px
  xl: 32px
  screen-edge: 20px
  gutter: 16px
---

## Brand & Style
The design system is engineered for a Tunisian civic reporting platform, emphasizing **Trust, Authority, and Community Action**. The aesthetic leans into a **Corporate Modern** style with a focus on high legibility and systematic clarity, ensuring the interface feels like an official yet accessible public service.

The visual language is structured and reliable, utilizing a cool-toned palette to maintain a calm atmosphere even when users are reporting urgent issues. It avoids excessive decoration in favor of functional clarity, ensuring that the transition between Latin and Arabic scripts feels seamless and intentional. The emotional response should be one of empowerment—moving from the frustration of a civic problem to the confidence of a tracked resolution.

## Colors
The palette is anchored by **Civic Blue**, a color associated with stability and institutional reliability. 

- **Primary & Neutrals**: The background uses a subtle blue-tinted off-white (`#F4F6FB`) to reduce screen glare and distinguish the app from generic white-label tools. Surfaces are pure white to create a clear "card-on-canvas" hierarchy.
- **Functional Colors**: Standardized semantic colors (Red, Green, Amber) are used strictly for status reporting—Urgent, Resolved, and In Progress.
- **Typography Colors**: Deep navy (`#0F172A`) is used for primary text to ensure high contrast and AAA accessibility, while Slate and Gray tones handle secondary information and metadata.

## Typography
This design system employs a dual-font strategy to support the bilingual nature of the application (Latin/Arabic). 

- **Latin (Nunito Sans & Inter)**: Nunito Sans provides a friendly yet bold personality for headlines, while Inter offers a systematic, neutral feel for data-heavy body text.
- **Arabic (Cairo)**: Cairo is selected for its modern Kufi style which harmonizes perfectly with geometric sans-serifs.
- **Line Heights**: A critical 1.8x line-height multiplier is applied to all Arabic text to accommodate the script's vertical ascenders and descenders without crowding.
- **Alignment**: Typography must support RTL (Right-to-Left) layouts. Headlines should be start-aligned based on the active locale.

## Layout & Spacing
The system follows a strict **8px spacing scale** to ensure visual rhythm across the React Native environment. 

- **Mobile Philosophy**: The layout uses a fluid grid with a fixed **20px horizontal margin** for the screen edges. 
- **RTL Handling**: All horizontal spacing, padding, and margins must be defined using logical properties (`paddingStart`, `marginStart`) rather than Left/Right to ensure the UI flips correctly for Arabic users.
- **Touch Targets**: All interactive elements maintain a minimum hit area of 44x44dp, regardless of their visual size.

## Elevation & Depth
Depth is created through **Tonal Layering** and **Layered Ambient Shadows**. 

- **Base Layer**: Background (`#F4F6FB`).
- **Level 1 (Cards)**: White surface with a soft, diffused shadow: `offset: (0, 2), blur: 8, opacity: 0.05, color: #0F172A`. Used for report cards and news items.
- **Level 2 (Floating Action Buttons & Modals)**: Higher contrast shadow to indicate immediate proximity to the user: `offset: (0, 4), blur: 12, opacity: 0.12, color: #0F172A`.
- **Borders**: Level 0 elements (like input fields or dividers) use a subtle border (`#E2E8F0`) instead of shadows to remain grounded.

## Shapes
The shape language balances approachability with professionalism through varied corner radii:

- **Structural (16px)**: Used for main content containers and cards. Large enough to feel modern and friendly.
- **Interactive (12px)**: Used for buttons and input fields. This slight reduction in radius compared to cards creates a clear visual distinction for "tappable" areas.
- **Utility (100px/Pill)**: Reserved for status badges, tags, and search bars to make them stand out as distinct, encapsulated units of information.

## Components

### Buttons
- **Primary**: Solid Civic Blue with white text. 12px radius. Height: 52px for main actions.
- **Secondary**: Ghost style with Border `#E2E8F0` and Text Primary.
- **Danger**: Solid Red for "Cancel Report" or "Delete" actions.

### Input Fields
- **Default State**: White background, 12px radius, 1px border (`#E2E8F0`). 
- **Focus State**: 2px border in Primary Blue.
- **Labels**: Always placed above the input in `label-sm` style.

### Cards
- White surface, 16px radius, Level 1 shadow. 
- Padding: 16px internal padding.
- Content: Feature an icon in "Duotone" style to represent the reporting category (e.g., Water, Roads, Electricity).

### Status Badges
- Used for "Pending", "In Progress", and "Resolved".
- Style: Tinted background (10% opacity of the semantic color) with high-contrast text of the same color. 100px radius.

### Iconography
- **Style**: Phosphor Icons.
- **Actions**: "Regular" weight for navigation and utility buttons.
- **Features**: "Duotone" for category icons (e.g., a duotone "Drop" icon for water issues) to add a sophisticated, branded touch.
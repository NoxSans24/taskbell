---
name: Pop Comic Productivity
colors:
  surface: '#fcf9f8'
  surface-dim: '#dcd9d9'
  surface-bright: '#fcf9f8'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f6f3f2'
  surface-container: '#f0eded'
  surface-container-high: '#eae7e7'
  surface-container-highest: '#e5e2e1'
  on-surface: '#1c1b1b'
  on-surface-variant: '#424753'
  inverse-surface: '#313030'
  inverse-on-surface: '#f3f0ef'
  outline: '#727784'
  outline-variant: '#c2c6d5'
  surface-tint: '#005bbe'
  primary: '#0059b9'
  on-primary: '#ffffff'
  primary-container: '#2772dc'
  on-primary-container: '#fefcff'
  inverse-primary: '#acc7ff'
  secondary: '#7c5800'
  on-secondary: '#ffffff'
  secondary-container: '#fdb700'
  on-secondary-container: '#6a4b00'
  tertiary: '#8e4a00'
  on-tertiary: '#ffffff'
  tertiary-container: '#b25f00'
  on-tertiary-container: '#fffbff'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d7e2ff'
  primary-fixed-dim: '#acc7ff'
  on-primary-fixed: '#001a40'
  on-primary-fixed-variant: '#004491'
  secondary-fixed: '#ffdea7'
  secondary-fixed-dim: '#ffbb18'
  on-secondary-fixed: '#271900'
  on-secondary-fixed-variant: '#5e4200'
  tertiary-fixed: '#ffdcc4'
  tertiary-fixed-dim: '#ffb77f'
  on-tertiary-fixed: '#2f1500'
  on-tertiary-fixed-variant: '#6f3900'
  background: '#fcf9f8'
  on-background: '#1c1b1b'
  surface-variant: '#e5e2e1'
  comic-canvas: '#FFF9EC'
  comic-surface: '#FFFFFF'
  accent-red: '#E91E4B'
  accent-purple: '#8429D8'
  text-muted: '#555555'
  border-ink: '#171717'
  status-success: '#197447'
  status-warning: '#8A4B00'
  status-error: '#B42335'
  status-info: '#245CB5'
typography:
  display:
    fontFamily: Plus Jakarta Sans
    fontSize: 38px
    fontWeight: '800'
    lineHeight: 44px
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 30px
    fontWeight: '800'
    lineHeight: 36px
  headline-lg-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '800'
    lineHeight: 32px
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 22px
    fontWeight: '700'
    lineHeight: 28px
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 18px
    fontWeight: '700'
    lineHeight: 24px
  body-lg:
    fontFamily: DM Sans
    fontSize: 16px
    fontWeight: '500'
    lineHeight: 24px
  body-md:
    fontFamily: DM Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  body-sm:
    fontFamily: DM Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
  label-lg:
    fontFamily: DM Sans
    fontSize: 14px
    fontWeight: '700'
    lineHeight: 18px
  label-md:
    fontFamily: DM Sans
    fontSize: 12px
    fontWeight: '700'
    lineHeight: 16px
  label-sm:
    fontFamily: DM Sans
    fontSize: 11px
    fontWeight: '700'
    lineHeight: 14px
  caption:
    fontFamily: DM Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  gutter-tablet: 1.5rem
  margin: 1rem
  margin-tablet: 1.5rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 1rem
  space-lg: 1.5rem
  space-xl: 2rem
  space-2xl: 3rem
---

## Brand & Style

This design system expresses a high-energy, pop-art comic visual style tuned precisely for daily mobile productivity. It merges bold neo-brutalist paneling, high-contrast outlines, speech-bubble badges, and retro halftone textures with rigorous ergonomics. The visual tone transforms mundane task management into an engaging, tactile experience that feels punchy and rewarding without introducing cognitive fatigue.

Targeted at dynamic Indonesian smartphone users, young professionals, and students, the interface embraces an upbeat, approachable tone with crisp Indonesian microcopy. The visual treatment avoids corporate sterility through thick outlines and hard-edge drop shadows, yet preserves strict utility: text remains razor-sharp, checklists are immediately scannable, and data visualization avoids noisy decorative clutter behind actionable elements.

## Colors

The palette draws inspiration from classic screen-printed comic books, grounded on a warm paper tone rather than clinical white. 

- **Primary (`#347BE5`)**: High-impact comic cyan-blue used for main calls to action, active navigation tabs, checklist check indicators, and key focus states.
- **Secondary (`#FFB900`)**: Vivid comic yellow reserved for high-priority task tags, notification badges, milestone star bursts, and secondary highlights.
- **Tertiary (`#FF8A00`)**: Warm pop orange for progress metrics, urgency flags, and intermediate highlights.
- **Neutral / Ink (`#171717`)**: Pure comic ink black utilized for structural 2px outlines, hard offset drop shadows, and high-legibility typographic hierarchies.
- **Canvas & Surface**: `#FFF9EC` delivers the tactile off-white newsprint feel for main app backdrops, while `#FFFFFF` provides clean contrast on actionable cards and dialog surfaces.
- **Named Accents**: Red (`#E91E4B`) marks critical alerts and deletions, while Purple (`#8429D8`) accents analytical stats and recurring schedules.

All interactive elements must preserve WCAG AA contrast. Never place small light text directly on yellow or orange backgrounds without a dark neutral enclosing pill or high-contrast ink outline.

## Typography

Typography balances playful character with functional density. **Plus Jakarta Sans** provides rounded geometry and bouncy rhythm for display titles, comic headers, empty-state banners, and metric callouts. **DM Sans** delivers clear, compact geometry for checklists, input forms, timestamps, and settings options.

Typography scale rules:
- Keep `display` and `headline-lg` styles concise—never wrap them beyond 2-3 lines.
- Indonesian words are often longer than English equivalents; always allow `body-md` and `label-md` labels adequate vertical flex without clipping.
- Never place text beneath decorative halftone dot patterns.

## Layout & Spacing

The layout is built around a predictable 4px base unit (8px step scale) to support single-column mobile task views. 

- **Mobile (<600px)**: Single column with a bottom navigation bar, anchored input drawers, 16px screen margins, and 12px gaps between task cards. 
- **Tablet / Foldable (600px–1024px)**: 2-column panel layout; task lists on the primary panel (60%) and detail/analytics inspector on the trailing panel (40%).
- **Desktop / Wide Landscape (>1024px)**: Centered container capped at 960px with a persistent left rail navigation.

Minimum touch target sizes across all viewports are strictly 48×48px. Form fields adhere to a single-column flow to prevent thumb strain.

## Elevation & Depth

This system avoids Gaussian blurs, soft diffused drop shadows, and glassmorphism. Visual depth is achieved through structural comic offset shadows and crisp borders:

- **Border Standard**: Consistent 2px solid `#171717` line weight across cards, inputs, dialogs, badges, and buttons.
- **Hard Drop Shadow**: Offset shadow `3px 3px 0px #171717`. Applied to elevated cards, action buttons, floating action buttons (FAB), and floating modals.
- **Pressed State**: On touch or click, components collapse the offset shadow to `0px 0px 0px #171717` while translating `3px` down and `3px` right, providing immediate mechanical feedback.
- **Stickers & Overlays**: Modals and bottom sheets use a solid 4px hard offset shadow against a 40% solid black backing overlay.

## Shapes

The roundedness level is set to `2` (0.5rem / 8px default, 1rem / 16px large). This produces friendly, cartoon-curved corners while preserving structural clarity:

- **Cards & Dialogs**: `rounded-lg` (16px) with a 2px outline and 3px hard offset.
- **Inputs & Row Containers**: `rounded-md` (8px) for comfortable containment.
- **Tags & Status Badges**: Pill-shaped (`rounded-full` / 999px) or stylized speech bubble tags with small SVG corner tails.
- **Accents**: Radial action stars, comic bubbles, and halftone dot panels must always feature clean vector geometric definitions.

## Components

### Buttons
- **Primary Button**: Background `#347BE5`, text `#FFFFFF`, 2px solid `#171717` border, 3px 3px 0 `#171717` shadow. Height 48px, horizontal padding `1.5rem`.
- **Secondary Button**: Background `#FFFFFF` or `#FFF9EC`, text `#171717`, 2px solid `#171717` border, 3px 3px 0 `#171717` shadow.
- **Destructive Button**: Background `#E91E4B`, text `#FFFFFF`, 2px solid `#171717` border.
- **Active / Pressed**: Translate `(3px, 3px)` with `0px` shadow offset.

### Task Cards
- Surfaces feature `#FFFFFF` fill, 2px `#171717` border, and 3px hard offset shadow.
- Content flow: Left circular custom SVG checkbox, task title in `body-lg` bold, metadata chips (due date, category, recurrence), and right kebab action trigger.
- Completed tasks: Strike-through text in `#555555`, subtle greyed checkbox tint, without removing outline definition.

### Checklist Rows & Progress
- Progress bars: 12px height, 2px `#171717` outer frame, filled with `#347BE5` or `#FFB900`, displaying progress counts like `2 dari 4 selesai`.

### Badges & Category Chips
- Compact pills with 2px borders and solid vibrant fills (`#FFB900` for High Priority, `#8429D8` for Analytics/Routine, `#347BE5` for Work).
- Speech bubble badge variants feature a tiny bottom-left vector tail for tips and empty states.

### Checkboxes & Radios
- 24×24px square with 6px rounded corners, 2px solid `#171717` border. When checked, background fills with `#347BE5` displaying a bold white SVG checkmark.

### Input Fields
- Fill `#FFFFFF`, 2px solid `#171717`, 8px radius.
- Focus state: Offset ring of 3px with `#347BE5` accent tint, zero interior glow.
- Helper labels: Bold Indonesian microcopy (e.g., `Nama Tugas`, `Tenggat Waktu`, `Catatan`).

### Iconography
- 100% SVG line icons with a consistent 2px black stroke weight matching UI outlines. No bitmap assets, icon fonts, or plain emojis as functional triggers.
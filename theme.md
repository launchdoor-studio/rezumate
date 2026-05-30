# Rezumate Theme

## Brand Feel

Rezumate should feel like a premium document utility for serious career work. The interface should be calm, structured, native, and readable. It should not look like a generic AI dashboard or a marketing landing page inside the app.

The visual direction is **Editorial Utility**:

- Warm document canvas
- Restrained surfaces
- Sharp native controls
- Deep green primary actions
- Muted status colors
- Minimal decoration
- Strong readability over visual novelty

## Color Tokens

Use this palette for the iOS app:

| Token | Hex | Use |
| --- | --- | --- |
| App Background | `#F4F1EB` | Main screen background |
| Surface | `#FAF8F3` | Panels, grouped sections |
| Elevated Surface | `#FFFFFF` | Text inputs, focused document areas, modals |
| Ink | `#111318` | Primary text |
| Muted Text | `#6E7178` | Secondary text, helper copy |
| Border | `#DDD8CF` | Panel and input borders |
| Primary | `#183A37` | Main actions, selected controls |
| Link | `#2858A6` | Secondary actions and document affordances |
| Success | `#28715A` | Strong scores, completed states |
| Warning | `#B7791F` | Missing keywords, medium scores, warnings |
| Error | `#B42318` | Failed requests and destructive states |

Do not introduce additional dominant colors without updating this file first.

## Typography

- Use native San Francisco for most UI.
- Use serif type only for brand moments and report emphasis.
- Good serif use: auth app name, large score number, one report heading.
- Bad serif use: form labels, buttons, list rows, dense settings, helper text.
- Keep body text compact and readable. Do not use viewport-scaled type.

## Layout and Spacing

- Prefer native iOS structure over marketing layout.
- Workflow screens should feel like forms and reports, not landing pages.
- Use `16pt` outer padding for standard screens.
- Use `12-16pt` internal panel padding.
- Keep repeated list rows compact.
- Avoid oversized hero cards inside signed-in product screens.

## Surfaces and Elevation

- Main background is flat warm paper.
- Panels use `Surface` with a thin `Border`.
- Inputs and document text areas use `Elevated Surface`.
- Default corner radius is `8pt`.
- Use borders more often than shadows.
- Shadows are reserved for system-level floating elements, not every card.

## Controls

- Primary buttons use `Primary` fill with white text.
- Secondary buttons use border styling with `Primary` or `Ink` text.
- Destructive actions use `Error`.
- Inputs must have a clear border and stable size.
- Tags use low-opacity fills with borders. Status colors should communicate state, not decoration.
- Icons should clarify actions, not decorate empty space.

## Screen-Specific Rules

### Auth

- Logo and app name are identity, not decoration.
- Keep the screen centered and quiet.
- Sign in with Apple is the primary action.

### Analyze

- Treat this as a focused form workflow.
- Resume upload is a compact document row.
- Job description editor should feel like a document field.
- The analyze button is the strongest visual action on the screen.

### Results

- Treat this as a report.
- Score header may use serif emphasis.
- Breakdown rows should be compact and easy to scan.
- Keyword chips should be muted and readable.
- Rewrite and export controls should feel like utilities.

### History

- Use native list-style rows.
- Avoid large floating cards.
- Score, title, date, and chevron should be easy to scan.

### Profile

- Use a simple settings layout.
- Do not place the logo as filler.
- Sign out should be clear but not visually dominant.

## Anti-Patterns

- No rainbow, pastel, or multi-color gradients.
- No pure-white cards stacked over tinted backgrounds.
- No generic AI-dashboard visual tropes.
- No oversized hero panels inside workflow screens.
- No decorative blobs, glows, or bokeh.
- No random logo placement.
- No excessive corner radius.
- No decorative color unless it communicates state.

## Accessibility Rules

- Text must remain readable against every surface.
- Do not rely on color alone for error, warning, or success states.
- Buttons and rows must keep a comfortable tap target.
- Dynamic Type should not cause labels to overlap or truncate critical actions.
- Disabled states must remain visibly distinct.

## Implementation Checklist

- Keep theme tokens centralized in `DesignSystem.swift`.
- Use flat `rezScreenBackground()` for main screens.
- Use `RezCard` for grouped panels only.
- Use `rezInputSurface()` for text editors and document areas.
- Audit new screens against this file before committing.

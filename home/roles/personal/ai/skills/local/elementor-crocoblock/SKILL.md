---
name: elementor-crocoblock
description: Use when starting or building a Crocoblock (JetEngine/JetTabs/JetElements) + Elementor + WordPress site — "new elementor site", "build this page in elementor", "crocoblock site", "start a wordpress build". Carries the verified layout recipe (hero, section rhythm, gap scale, token binding) plus known EMCP/Elementor/JetEngine gotchas, so a build starts from proven values instead of re-deriving them per project.
---

# Elementor + Crocoblock builds

Layout recipe and gotcha list distilled from real Oceanus Oral Center builds (multiple pages,
several rounds of user refinement). Apply the recipe by default; deviate only with explicit
approval for that specific section.

## When to use

Any task that builds or restyles a page/section on a WordPress + Elementor site, especially one
using Crocoblock plugins (JetEngine, JetTabs, JetElements, JetSmartFilters, etc.) through the EMCP
MCP tools (`add-container`, `get-page-structure`, `get-widget-schema`, `update-element`, …).

## Tooling reality

- Page/container/widget structure is reachable via EMCP tools — build there.
- **JetEngine Relations, Query Builder, and Listing Item templates are wp-admin-only config, not
  reachable through the Elementor MCP tools.** Split the work: hand the user the exact wp-admin
  steps (relation type, direction, reference), do the DB/plugin/build parts yourself.
- Before any DB write, `describe-table` — never guess a plugin's schema. Use `insert-row`
  (reversible, snapshotted), not raw `INSERT`.
- Verify every write via `get-element-settings` (or a DB read). A bare `"success":true` from a
  tool is not proof — atomic widgets and dynamic-tag controls have silently no-op'd or written the
  wrong shape before.

## Layout system (the core recipe)

Every section follows the same two-layer container pattern:

- **Outer container** — full width, carries the background (color/image/gradient spans edge to
  edge). Horizontal padding: **16px on desktop, tablet, and mobile — same value everywhere.**
  Vertical padding: **80px** top/bottom (section rhythm), section-specific if the design calls for
  more/less. Never hand-pick per-section left/right pixel padding to fake centering — that's what
  the inner layer does.

  Why 16px on desktop too, not just tablet/mobile: a `boxed` inner content wrapper caps at the
  kit's `container_width` (1140px on this build) and centers via margin. That centering only kicks
  in once the viewport is wider than the boxed width plus its own gutter. On viewports between the
  tablet breakpoint and roughly 1140+2×gutter (~1025–1139px — small laptops), a boxed inner with
  zero outer padding touches the screen edge. A uniform 16px outer gutter closes that band and
  costs nothing on wide screens (absorbed into the centering margin above ~1172px).

- **Inner content wrapper** (nested inside the outer, holds the actual content) —
  `content_width: "boxed"` (Elementor's native mechanism, anchored to the kit's `container_width`).
  This is the default; use it without asking.

  **Full-width exception**: only when the design calls for a deliberate full-bleed split (image
  fills half the section edge-to-edge, etc.) — use `content_width: "full"` on that inner wrapper,
  and only after explicit approval for that specific section. Don't infer it from an unfinished or
  unvalidated reference section elsewhere on the site.

- **Gap scale**: 24px between tightly related elements (heading + subtitle, icon + label), 56px
  between major sub-blocks within a section. Pick from this scale rather than inventing a new gap
  value.

- **Grids**: column/row count is `{unit: "fr", size: N, sizes: []}` — see gotcha below for why the
  `sizes` array must stay empty. Standard responsive collapse: 2 cols desktop → 1 col tablet (set
  `grid_columns_grid_tablet` explicitly); wider grids (3–5 cols) usually collapse to 1 on mobile,
  sometimes 2 on tablet — match the design.

- **Avoid unnecessary containers.** Flatten wrapper containers that add no layout value (no
  padding, no background, no distinct responsive behavior) — deep nesting (4–5 levels for a simple
  two-column block) makes the tree harder to maintain and often the source of the boxed/full-width
  gotcha below.

### Hero recipe

Verified identical across every finished hero on this build:

- `flex_direction: column`, `justify_content: center`, `align_items: center`, gap 24px.
- `min_height`: **85vh desktop / 70vh tablet / 80vh mobile**.
- Padding: 0 (the hero's own min-height handles vertical space); horizontal gutter still 16px on
  all breakpoints per the outer-container rule above (0 on desktop only if explicitly following an
  older/different design system — confirm before deviating).
- Background: image, `background_size: cover`, `background_position: center center`.
- Overlay: `background_overlay_background: gradient`, two-stop gradient
  `rgba(49,36,23,0.8) → rgba(15,28,42,0.8)` at **180deg**, opacity 1. (Colors are this project's
  brand darks — swap for the new project's own dark brand tones, keep the two-stop 180deg
  structure and ~0.8 opacity as the pattern.)
- `custom_css: "selector { position: relative; }"` on the hero container (needed for absolutely
  positioned children, e.g. a scroll-cue icon) — an already-approved pattern, safe to reuse
  verbatim; anything beyond this exact rule is a new Custom CSS need and requires asking first.

## Tokens & code discipline

- Bind every color/typography value to an existing kit global by `_id` — never hardcode hex or
  raw font sizes once a global exists for that value. Pull the project's token catalog once at the
  start of the build (typically via `get-global-settings` / `list-global-classes`) rather than
  guessing IDs.
- If a stale literal value sits alongside a `__globals__` binding for the same control, strip it —
  dead weight; globals win at render time regardless, but a clean settings object avoids confusion
  later. Do this as routine cleanup whenever you touch that widget; no need to ask.
- Uppercase text (eyebrows, labels): type the copy in normal case and apply
  `typography_text_transform: "uppercase"`. Never type manual caps to match a design's visual
  style — breaks screen readers, copy edits, search.
- **Ask before**: creating a brand-new global color/typography token, adding any custom PHP/JS
  snippet, or adding Advanced > Custom CSS on an element (beyond reusing an already-approved
  pattern verbatim, per the hero rule above).
- **Never** hand-edit or delete Elementor's compiled/generated CSS
  (`wp-content/uploads/elementor/css/*.css`) — it's regenerated output, not source. If it's stale
  and not auto-regenerating, ask the user to run Elementor → Tools → Regenerate CSS.

## EMCP / Elementor / JetEngine gotchas (hit and fixed on real builds)

- **Grid column format**: must be `{unit: "fr", size: N, sizes: []}`. The `sizes`-array form
  (populating `sizes` instead of `size`) silently defaults to 3 columns regardless of intent — set
  `size` and leave `sizes` empty.
- **`_flex_size: "grow"` sets `flex-shrink: 0`**, which stops text from wrapping and causes
  horizontal overflow once a sibling is width-constrained. Use `_flex_size: "custom"` with explicit
  `_flex_grow: 1, _flex_shrink: 1` instead of the `"grow"` preset.
- **A plain CPT post with no prior Elementor edit** needs `_elementor_edit_mode: "builder"`
  postmeta inserted manually before build tools work correctly — otherwise `add-container` and
  similar silently write a plain-text fallback into `post_content` instead of real Elementor data.
  Check `is_elementor` / this meta before trusting a builder tool call on an unfamiliar post.
- **Any nested (non-top-level) container left at the auto-defaulted `content_width: "boxed"`**
  snaps to the kit's literal width (e.g. 1140px) regardless of its flex context — always set
  nested containers explicitly to `"full"` unless boxed is actually intended there.
- **Responsive width cascade**: fixed-width elements (split images, thin dividers) need **explicit**
  `width_tablet` / `width_mobile` overrides — a desktop-only `width` on a `_flex_size: custom`
  element doesn't reliably cascade down, causing tablet overflow or a divider rendering as a full
  bar instead of a thin line. Pair with parent `flex_direction_tablet` / `_mobile: "column"` where
  the design stacks on smaller screens.
- **Font Awesome**: this install (and likely similar Crocoblock/Elementor stacks) bundles FA5 only
  — use `fas fa-…` class names. FA6 names and `fab fa-…` (Brands) render blank; no brands stylesheet
  is enqueued. For a brand icon design calls for, reuse an existing SVG asset recolored via a
  filter, or ask before adding a new icon library.
- **Elementor's classic button widget silently applies a catalog-default background** (a specific
  accent color baked into a global button rule) if `background_background` / `background_color`
  are left unset — not transparent. An outline/transparent button needs
  `background_background: "classic", background_color: "transparent"` set explicitly.
- **Atomic widgets** (Elementor 4.x `e-*` types: `e-form-submit-button`, etc.) store style as a
  local CSS class with per-variant `props` + `custom_css`, a different shape from classic widgets'
  flat `custom_css` setting, and often have no icon control at all — check
  `get-widget-schema(type, full:true)` before assuming a control exists; verify writes landed by
  re-reading `_elementor_data`, don't trust a bare success flag.
- **Theme Builder template conditions**: an `include` condition of `"singular"` matches *all*
  singular content, not just the intended post type — this has silently hijacked unrelated pages
  before (a 404 template caught intercepting every normal page at 200 status). Set precise
  conditions (e.g. `[["include", "404"]]`, `[["include", "singular", "tratamentos"]]`) and verify
  by checking the actual served body on a few unrelated URLs, not just the HTTP status code.
- **Figma grids sometimes declare one more cell than they populate** (a 3×2 layout with only 5 real
  cards) — check the rendered screenshot before fabricating a plausible-looking extra card to fill
  the grid.
- **Figma image fills can be watermarked stock-photo previews** (paid/unlicensed) — screenshot
  before extracting; source a free licensed equivalent if so.
- **Playwright full-page screenshots can fire before lazy-loaded images finish loading**, producing
  false "missing image" reports below the first viewport. Force `loading="eager"` (or scroll
  through once) before treating a screenshot as ground truth; confirm via `naturalWidth` in
  `browser_evaluate` if something looks missing.

## Build loop

1. Build top to bottom (hero first), verifying visually every 2–3 sections rather than the whole
   page at once — catches a wrong pattern before it repeats across ten more sections.
2. Pull exact copy/spacing/tokens from the design source at the point of building that section
   (never estimate from a thumbnail or a whole-page screenshot).
3. Reuse already-established patterns from earlier sections/pages on the same site (button styles,
   icon-circle treatment, hero recipe) rather than reinventing per section.

## Verification

- `curl -s -o /dev/null -w "%{http_code}" <url>` → 200 on the built page and a spot-check of a few
  unrelated pages (catches template-condition regressions).
- Playwright full-page screenshots at 1440 / 768 / 390px; confirm
  `documentElement.scrollWidth === document.documentElement.clientWidth` (no horizontal overflow)
  at each width.
- Compare the screenshot section-by-section against the design source.

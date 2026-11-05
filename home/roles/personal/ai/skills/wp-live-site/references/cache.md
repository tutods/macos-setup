Cache runbook: LiteSpeed Cache, WP Fastest Cache, Elementor CSS cache, stale reads.

## LiteSpeed Cache

- Never "Purge All" (any variant) without the user's OK: it colds the cache for every visitor. A stale page gets "Purge this page" from the admin bar on that URL.
- Auto-purge on save is selective: a post save purges itself and its archives and home. Check what else embeds the changed content (other pages, templates) and purge those URLs one by one.
- Cached pages keep old inline output (snippet HTML, inline CSS and JS) until they expire, up to 7 days by default, or get purged.
- Page cache stores 404 responses: a new redirect may need that URL purged.
- Preview links and logged-in previews can serve stale optimised CSS: append `&LSCWP_CTRL=before_optm` to see the unoptimised layout.
- Save LiteSpeed settings forms with `form.requestSubmit()` via eval, then confirm the saved banner and reload.

Risky optimisation settings, off unless the user asks and every page is retested:

- UCSS (and UCSS Inline): drops Elementor V4 nested `&` rules and rules after `:has()`.
- JS Combine: breaks `wp` globals (`wp is not defined`).
- jQuery defer, JS "Delayed": break consent banners, first taps, search, variation swatches.
- Load CSS Async: flash of unstyled content.
- Cache Mobile: only on with a separate mobile render.
- Remove Query Strings: serves stale Elementor CSS.
- Partial script defer or delay through a snippet: broke logged-in swatches. Every smoke test includes a logged-in interaction.

Safe defaults: CSS/JS/HTML minify, CSS combine, JS Deferred with jQuery excluded, font-display swap. Exclude cart, checkout and account URIs from cache.

Stale reads:

- With LiteSpeed object cache, a REST read right after a write can return the old object while the live page already shows the change. Trust the live HTML with a cache-buster (`?cb=<timestamp>`) and `wp/v2/<type>/<id>?context=edit` before reporting a failed save.
- Never read-modify-write from a stale read: it reverts the change.

## WP Fastest Cache

- Clear the cache after every content, snippet or CSS change: admin bar "Clear Cache" (or "Delete Cache and Minified CSS/JS" when a CSS or JS change does not show).
- Verify as a guest with a cache-buster; logged-in admins usually bypass the cache.

## Elementor CSS cache

- After REST or MCP writes: `DELETE elementor/v1/cache`, then warm the URL (the first guest load can take 60 s or more).
- Atomic CSS files carry a 1-year max-age: rule out browser cache before restyling. Details in elementor.md.

## Diagnosing "still old"

1. Fetch the page as a guest with a cache-buster and check the response headers (`x-litespeed-cache`, `age`).
2. Compare stored value, guest HTML and the asset URL with `{cache: 'reload'}`.
3. Purge only the layer that is stale: the one page, the Elementor CSS, or the browser.

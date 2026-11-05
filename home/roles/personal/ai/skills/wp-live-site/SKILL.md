---
name: wp-live-site
description: >
  Operate a live WordPress site through the logged-in wp-admin browser:
  content, page builders (Elementor, Crocoblock/JetEngine), snippet plugins
  (WPCode, FluentSnippets), SEO plugins, cache, blog posts and products,
  the site's Instagram/Facebook via Meta Business Suite, PT-PT copy checks.
  Use when a task edits or verifies a client site, not plugin/theme source
  code (that is the wordpress-skills plugin).
---

A live site has no SSH, WP-CLI or application password. Every read and write goes through the user's logged-in wp-admin session in Orca's embedded browser, or the site's Elementor MCP when one is configured. Each write is a **live write**: backed up first, verified after.

## Session

1. Load `orca-cli` and resolve the Orca executable.
2. Open your own tab (`tab create`), record its page id, pass `--page <id>` on every command. Close only your own tab. `goto` resets the viewport, re-apply `viewport` after each navigation.
3. Check the session: load `/wp-admin/`. A login screen means stop and ask the user to log in; the login URL may be hidden by a plugin, never store or guess it.
4. Discover the stack once per site: active plugins (`/wp-json/wp/v2/plugins` or Plugins screen), theme, page builder, cache plugin, SEO plugin, snippet plugin. Read the project `CLAUDE.md`/memory for site-specific IDs before touching anything.

Done: own tab open, logged in, stack known.

## Reading and writing

- REST runs inside the tab: `orca eval` with `fetch('/wp-json/...', {headers: {'X-WP-Nonce': wpApiSettings.nonce}})` from an admin page. Custom post meta values are strings. A REST create that errors on meta can still insert the post: list and trash orphans after any failed create.
- Plugin admin screens built in Vue/React are edited through their state (`el.__vue__`, CodeMirror view), then their own Save button in a separate `eval`. Never type keystrokes into the OS window (`orca type` loops); use JS `.click()` and `form.requestSubmit()`.
- Settings objects: GET the full object, back it up, change keys, POST the whole object, re-GET and diff. A partial POST replaces the option and wipes every key it omits.
- Concurrency: re-read a document fresh before each save; never write from an older GET. Another session may edit the same site.
- Load: one request at a time, ≥0.5 s apart, stop on the first connection error. Shared hosts go down under parallel scans.
- Prefer native features: core, then the installed plugin's own setting, then a snippet. Name the native option checked before adding a snippet.

## Live write loop

1. **Backup**: save the current value to `backups/<kind>-<id>-<YYYY-MM-DD>-before-<change>.<ext>` in the project.
2. **Write** the change.
3. **Verify**: re-read the stored value, then load the live page with a cache-buster, desktop and mobile (375 px, no horizontal overflow). Check one unrelated page too.
4. **Revert** from the backup at once on a side effect, and report it.

Done: stored value and rendered page both show the change, unrelated page unchanged, evidence quoted in the report.

Destructive or site-wide steps (deleting content or media, Purge All, header/footer templates, bulk edits, permalink or SEO-wide settings) need the user's direct OK in this turn.

## Plugin runbooks

Read the matching file before working on that plugin:

- Elementor (MCP, V3 editor via `$e.run`, publish order, CSS cache): [elementor.md](references/elementor.md)
- Crocoblock (JetEngine CPTs, meta fields, Query Builder macros, listing grids, Jet Tabs/Accordion): [crocoblock.md](references/crocoblock.md)
- Code snippets (WPCode, FluentSnippets): [snippets.md](references/snippets.md)
- SEO (SEOPress, 404 triage, redirects, llms.txt, robots.txt): [seo.md](references/seo.md)
- Cache and performance (LiteSpeed, WP Fastest Cache, Elementor cache): [cache.md](references/cache.md)
- Blog posts and WooCommerce products (template clone, scheduling, product batches): [content.md](references/content.md)
- Instagram/Facebook (assets, captions, Meta Business Suite scheduling, reviews): [social.md](references/social.md)
- Any human-read text (copy, SEO meta, alts, captions, client docs): [text-validation.md](references/text-validation.md), PT-BR scan `python3 scripts/ptbr-scan.py <files>`
- Restore, migration, scraping a WP site: [ops.md](references/ops.md)
- Orca browser quirks (clicks, scroll, screenshots): [orca.md](references/orca.md)

A plugin with no runbook: read its admin screen and docs, then follow the live write loop. Record the gotchas you hit in the project memory.

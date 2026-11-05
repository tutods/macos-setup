SEO runbook: SEOPress redirects and 404 triage, slug changes, llms.txt, htaccess, robots.txt, Site Kit data.

## Ground rules

- SEOPress is the only SEO tool: no second plugin, no hand-written meta or schema snippet when SEOPress has the setting.
- Never disable the 404 log, not for performance or log growth. Clear entries instead. A settings change that would touch it: stop and ask.
- SEOPress settings objects (`seopress/v1/options/<name>-settings`, `pro-settings`) replace the whole option on POST. A partial `pro-settings` POST once wiped local business, rich snippets, llms.txt and WooCommerce settings.
- Re-export GSC and GA4 baselines before judging any SEO change.

## 404 log

- 404 entries and redirects share post type `seopress_404`. Read 404s with `GET seopress/v1/redirections?view=404` (no `orderby`), `per_page` max 100, response `{data, total, totalPages}`.
- SEOPress skips curl's default user agent: test with a browser UA.
- Routine: pull the whole log, back it up as JSONL, triage locally into a file with lines `REDIRECT (n): ids`, `CHECK (n): ids`, `DELETE (n): ids`.
  - REDIRECT: old real URLs (product, category, post, page slugs) 301 to the closest live page.
  - DELETE: scraper image URLs (thumbnail sizes, broken srcset strings), secret-file probes (`.env`, `.npmrc`, `credentials.json`), verification files for methods not in use.
  - DELETE, never redirect, pagination URLs (`/page/N/`): when the listing grows the page exists again and a redirect would hide it.
  - CHECK: anything ambiguous, for the user.
- Apply: convert with `PUT seopress/v1/redirections/<id>` `{destination: <full URL>, type: "301", enabled: true, param: "exact_match"}`. Delete with `DELETE seopress/v1/redirections/bulk {ids}` in chunks of 50, 1 s apart.
- Admin fallback: the 404 list shows 100 rows; use the header select-all and bulk trash. Never tick rows one by one in the React screen (it hangs the browser).

## Redirects

- New: `POST seopress/v1/redirections` `{origin: "path/without/leading/slash/", destination: <full URL>, type: "301", enabled: true, param: "exact_match"}`.
- A 404 entry with the same origin shadows the redirect: delete it first.
- Use exact match. Regex redirects can fail to fire and do not match upload paths. Exact match fails with a query string: test without `?cb=`.
- Page cache stores 404 responses: purge that one URL, then verify old URL, 301, 200 with curl.
- List: `GET seopress/v1/redirections?page=N` only (20 per page; `view=redirections` and `per_page` are rejected).
- Every rename or slug change gets a 301 in the same step. Sweep content, menus, header and footer templates, llms.txt and existing redirects that point at the old URL, and repoint them straight to the new target (no chains).
- Trashed product: 301 to its category, never to a single product (single items sell out and chain). Repoint redirects whose destination was that product.
- Retiring a post: back up, find references, create the 301, then trash.

## Meta fields

- Post, page and product SEOPress meta (`_seopress_titles_title`, `_seopress_titles_desc`...) writes through `wp/v2/<type>/<id>` `meta`; send only that key.
- Term SEOPress fields: fetch the term edit form, build `FormData(form#edittag)`, set the one field, POST to the form action, re-read.
- Fallback meta in `titles-settings` is customer-visible text. Terms with their own stored copy override it: change those per term too.

## llms.txt and htaccess

- llms.txt: SEOPress PRO › llms.txt tab, a React textarea saved with its own Save button. The toggle reads "Disable this feature" while the feature is ON: leave it checked.
- Keep a local copy, back up the live text, paste, save, `curl /llms.txt` and diff.
- htaccess editor (SEOPress PRO) is React: save with a fetch POST to `admin-ajax.php`, `action=seopress_save_htaccess`, `_ajax_nonce=SEOPRESS_PRO_DATA.NONCES.htaccess`, `htaccess_content`. Back up the current file first; a broken file takes the site down, so load the home page right after.

## robots.txt

- Keep a local copy. Disallow wp-admin (allow `admin-ajax.php`), cart parameters, sort and filter query strings, internal search; list the sitemap.
- Content signals (contentsignals.org) go in their own block: `Content-Signal: search=yes, ai-input=yes, ai-train=no` (ask the user for the values).

## GSC and GA4 through Site Kit

- In a logged-in admin tab with `X-WP-Nonce`:
  - `GET google-site-kit/v1/modules/search-console/data/searchanalytics?startDate=&endDate=&dimensions=query&limit=` (add `url=<page>` to filter one page; query rows are a sample).
  - `GET google-site-kit/v1/modules/analytics-4/data/report?startDate=&endDate=&metrics[0][name]=sessions`.
- No API keys needed; works only while the session is logged in.
- AI-feature visibility is judged by search visibility, referrals and conversions, not by llms.txt or schema alone.

## GEO baseline

- Ship `llms.txt` (curated index: identity, key pages, contact) and `llms-full.txt` (full content as markdown).
- robots.txt states an explicit `Allow` for AI crawlers: GPTBot, ChatGPT-User, ClaudeBot, Claude-Web, PerplexityBot, Google-Extended, CCBot, Bingbot.
- Schema: `WebSite`, `CollectionPage`/`ItemList` on archives, `VideoObject` for embedded video, `BlogPosting` (not `Article`) for posts. Every field from real data; omit a type whose required field is missing, never guess a value.
- Title 50 to 60 characters, description 140 to 160 (Portuguese runs long: budget for it).
- Healthcare clients: no superlatives or guaranteed outcomes ("o melhor", "resultados garantidos", "sem dor") in any copy. Describe the service, never promise the result.
- WCAG 2.2 AA in the same pass: landmarks and skip link, keyboard access for custom widgets, form errors announced, measured contrast, `prefers-reduced-motion`.
- Report on-site readiness separately from off-site signals (citations, mentions, backlinks) that only exist after indexing.

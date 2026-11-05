Ops runbook: restoring or migrating a WordPress site from a backup, and scraping or importing content out of one.

## Restore from files and SQL dump

1. Set the domain on the target and let TLS provision first; search-replace against the final `https://` URL.
2. Restore content, not configuration: `wp-content/` (uploads, themes, plugins) and the database. Never copy the old `wp-config.php`; it points at the old DB host.
3. Check the dump's charset (`head -30 dump.sql | rg -i 'SET NAMES|character_set'`). Missing or `latin1` on UTF-8 content: import with `--default-character-set=utf8mb4`.
4. Verify accents right after the import (`SELECT post_title FROM wp_posts LIMIT 5`). Mojibake (`Ã£`, `Ã§`) means re-import with the charset forced, never fix in place.
5. Files into a container: `docker cp src/wp-content/. "$WP":/var/www/html/wp-content/`. The trailing `/.` copies the contents instead of nesting a second folder.
6. Ownership and perms: `chown -R www-data:www-data wp-content`, dirs 755, files 644.
7. Repoint URLs: `wp search-replace 'https://old' 'https://new' --all-tables --precise`. Without WP-CLI, a serialization-aware plugin (Better Search Replace).

- Never a raw SQL `REPLACE` across tables: it corrupts serialized widgets, options and postmeta silently. A raw `UPDATE` is safe only for `home` and `siteurl`.
- Redirect loop after the move: `siteurl`/`home` or other tables still hold the old URL. Re-run search-replace with `--all-tables`; never skip `wp_options` on import.
- Restoring the DB restores `wp_users`: log in with the old site's admin credentials.
- DB grants scoped per site: each site's user gets privileges on its own database only. Root only when the dump carries `CREATE DATABASE`/`USE`.
- Never publish the DB port to the internet for remote access: SSH tunnel or private network.
- Major engine swaps (MySQL 8 to MariaDB) and large PHP jumps: check compatibility before importing.

Verify: front page, `/wp-admin/`, a media file, a page with widgets or a page builder, container logs.

## Scraping and import

- AJAX-paginated grids (JetEngine listings, load-more, infinite scroll) hide every item past the first page from static HTML. Fetch them with a JS-running browser, or read the source data (REST, the listing's query) instead of the HTML.
- Fewer items than the sitemap lists means "not published" as often as "not imported". Count by status on the target (`?status=draft,publish` with auth, or a DB count grouped by status) before concluding content is missing.
- An importer that drafts items missing a scraped field fails silently: log every item it drafts and why.
- Resolve media by slug: `GET /wp-json/wp/v2/media?slug=<filename-without-extension>`, then use `source_url` and the id. Match on slug, not title.
- Throttle like any live read (see SKILL.md), back up the raw scrape as JSONL before transforming.

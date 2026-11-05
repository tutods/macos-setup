Code snippet runbook: WPCode and FluentSnippets editing, PHP lint, local mirrors, inline script gotchas.

## Before any snippet write

- Local mirror: `snippets/<plugin>-<name>.<ext>` in the project. Mirrors may be stale: read the live code and diff before relying on one.
- Lint PHP: copy to a temp file with `<?php` prepended (snippet plugins store code without it), then `nix shell nixpkgs#php -c php -l <tmp>`.
- Guard every array read and `isset` every optional key: a PHP warning at runtime can disable the snippet.
- When a cached shape changes (transient, option), bump the cache key.
- Translation and text overrides: one central snippet holds every override map. Add strings there, never a new translation snippet.
- Snippet CSS that styles one snippet's markup lives in a `<style>` block beside that markup; site-wide CSS goes in the central CSS snippet.

## WPCode

Edit:

1. Open `admin.php?page=wpcode-snippet-manager&snippet_id=<id>`.
2. Read the live code from the CodeMirror 5 instance: `document.querySelector('.CodeMirror').CodeMirror.getValue()`. Back it up, diff with the mirror.
3. Edit locally, lint.
4. One eval: `cm.setValue(code); cm.save();` then click `button[name=button][value=publish]` (Update).
5. Re-read with `fetch(location.href, {cache: 'no-store'})`, diff with local, confirm Active and the insert location.
6. Load a front-end page cold and warm.

- Never click `#wpcode_execute_now` or "Save to Library".
- New snippet: `admin.php?page=wpcode-snippet-manager&custom=1`, fill `[name=wpcode_snippet_title]` and the code, set the `wpcode_auto_insert_location` radio explicitly.
- PHP hooks: location `frontend_only` (runs on `wp`) or `everywhere`. "Site Wide Header" PHP runs inside `wp_head`, too late for cart or query hooks.
- WPCode auto-deactivates a PHP snippet on any PHP warning, also at runtime. After every push confirm it is still active.
- A pushed snippet can lose its first line and still pass lint: read the stored code back after each save.
- Saves over about 100 KB: stage the string on `window` in chunks across evals, then set it.

## FluentSnippets

Edit:

1. Open the snippet's edit screen.
2. CodeMirror 6 view: `const view = document.querySelector('.cm-content').cmView.view`.
3. Back up `view.state.doc.toString()`.
4. Eval A, set code: `view.dispatch({changes: {from: 0, to: view.state.doc.length, insert: CODE}, userEvent: 'input'})`. Build `CODE` as a JSON string (`jq -Rs . file`).
5. Wait for a marker from the new code in the editor (`orca wait --text <marker>`).
6. Re-pick "Run Everywhere" (click its label) or the intended scope. The editor opens showing "Admin Only" whatever is stored, and Update saves what it shows.
7. Eval B: JS-click "Update Snippet". Setting code and clicking in one eval does not save.
8. Reload, confirm code and scope in the editor and in the list view. Changes reach the front end a few seconds after save: recheck before concluding.

- "Admin Only" means `/wp-admin/` only and excludes `wp-login.php`. Login-screen code needs "Run Everywhere".

## Inline scripts under cache optimisers

- LiteSpeed rewrites inline scripts into deferred `data:` scripts and moves inline `<style>`. Find markup by id or a data attribute, never by `document.currentScript` siblings.
- Cached pages keep the old inline output until they expire or the page is purged (see cache.md).

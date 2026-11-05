Elementor runbook: MCP vs editor, `$e.run` commands, publish order, rendering gotchas, CSS cache.

## Pick the tool

- Elementor MCP first for any Elementor edit. It edits V4 atomic elements (`e-flexbox`, `e-heading`, `e-image`, `e-collection-loop`...), global classes, global variables and site parts.
- The MCP refuses V3 nodes (sections, columns, V3 containers, V3 widgets) with `elementor_v3_not_supported`. It also returns V3 widget text empty, hides Display Conditions and drops a dynamic tag's `fallback`.
- On `elementor_v3_not_supported`: show the user the error, ask, then fall back to the editor through Orca. Orca stays the tool for visual validation either way.

## MCP publish order

1. Read the document first (`get-page-structure` reads the published version; large output lands in a file, parse it with a script).
2. Mutate with `manage-elements` or `build-composition`.
3. `publish-document` right away. It promotes the whole autosave, so a pending autosave from someone else ships too.
4. Pages: re-POST `wp/v2/pages/<id> {"template":"elementor_header_footer"}` (or the template the page had).
5. `DELETE elementor/v1/cache`.

Pitfalls:

- A second build or `update-page-settings` before publishing discards the staged changes.
- `build-composition` appends. To rebuild, pass `mode: replace_children, parent_id: document`.
- Duplicated elements share local style ids: scope a style change through a fresh parent.
- Draft and scheduled posts: edit through MCP `manage-elements` or REST `meta._elementor_data` only. `publish-document` on them publishes immediately.

## Settings shapes that render

- Link: `{"destination": url, "isTargetBlank": false, "tag": "a"}`. The `{href,target}` shape is ignored without an error.
- Image: `{"src": {"id": N, "alt": "..."}, "size": "<registered size>"}`.
- Loop query: flat `query` object; a nested shape wipes the selection.
- Verify every link change by grepping the rendered page for the href.

## Layout defaults

- `e-flexbox` defaults to `padding: 10px` and `width: 100%`. `e-tabs` and `e-collection-loop` without a local style add 10px padding too.
- Never `width: 100vw`: with `scrollbar-gutter: stable` it overflows horizontally. Use `100%`.
- `e-svg` forces `fill=currentColor`.
- Shortcodes inside `e-paragraph` lose their markup: use the matching widget.

## Editor through Orca (V3 and what the MCP refuses)

1. Open `post.php?post=<id>&action=elementor` fresh in your tab (the save writes the state loaded at open). No autosave dialog pending.
2. Wait until `elementor.loaded`, `elementor.previewView` exists, `elementor.getPreviewContainer().children.length > 0` and the editor status is `open`. Saving earlier throws "reading 'toJSON'".
3. Find the container: `elementor.getContainer('<elementId>')`.
4. Run commands with `options: {external: true}` so the panel updates:
   - `$e.run('document/elements/settings', {container, settings: {...}, options: {external: true}})`
   - `$e.run('document/elements/create', {container: parent, model: {elType, widgetType, id: elementorCommon.helpers.getUniqueId(), settings}, options: {at: index, external: true}})`
   - `document/elements/move` (`{container, target, options: {at}}`), `document/elements/delete` (`{container}`), `document/elements/duplicate` (`{container}`).
5. Save: `$e.run('document/save/publish')`, or `$e.run('document/save/update', {force: true})` for an already published document.
6. Back up the widget settings JSON before step 4.

## Global styles

- A `__globals__` entry (global typography or colour) overrides the matching local setting. To change a value, unlink it: remove the key from `__globals__` in the same `settings` call, then set the local value.

## Computed styles in the editor

- Read styles from the preview iframe: `elementor.$preview[0].contentDocument.defaultView.getComputedStyle(el)`. The outer window's `getComputedStyle` returns wrong values.
- Entrance animations can sit stuck at their start state in the editor: finish them first (`el.getAnimations({subtree: true}).forEach(a => a.finish())`, or remove the `elementor-invisible` class) before measuring.
- V3 widgets sometimes lack `.elementor-widget-container`: target the widget class as well.

## Stale `post_content`

- Writing `_elementor_data` by REST or MCP updates the render but leaves `post_content` with the old text. It feeds RSS fallbacks, WooCommerce `description`, product feeds and some JSON-LD.
- Regenerate it with an editor save (`document/save/update`, `force: true`) through Orca, then compare the REST `content.raw` with the design.

## CSS cache

- After REST or MCP writes: `DELETE elementor/v1/cache`. The first guest load afterwards can take 60 s or more: warm the URL before timing or judging it.
- Atomic CSS files are served with a 1-year max-age. A "still broken" report may be the browser cache: compare `fetch(url, {cache: 'force-cache'})` against `{cache: 'reload'}` before restyling.
- Published atomic styles still serving old CSS: do a native editor save of that document; never purge the whole site for it.
- Elementor Performance settings: Google Fonts disabled plus "Load Google Fonts Locally" avoids a third-party font request.

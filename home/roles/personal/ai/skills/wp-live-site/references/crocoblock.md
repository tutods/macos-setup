Crocoblock runbook: JetEngine CPTs, meta fields, Query Builder, relations, listing grids, Jet Tabs and Jet Accordion.

## JetEngine admin screens are Vue apps

1. Open the edit screen (Post Types, Meta Boxes, Query Builder, Relations) in your tab.
2. Find the root component: `[...document.querySelectorAll('*')].find(e => e.__vue__?.$data?.generalSettings)?.__vue__`.
3. State lives in `$data`: `generalSettings`, `metaFields`, `advancedSettings` for CPTs and meta boxes; `args` for relations; query settings under the query component's data.
4. Back up `JSON.stringify(vm.$data)` first.
5. Change values with `vm.$set(obj, key, value)` so Vue tracks them. New array items go through `$set` or `splice`, never index assignment.
6. Separate `eval`: JS-click the save button by text: "Update Post Type", "Update Query", "Add Query" (new), "Update Relation".
7. Reload and re-read `$data` to confirm.

- Delete: click the row's delete, then the "Delete" button inside `.cx-vui-popup__footer`. The first click only opens the popup.
- Meta field values over REST are strings, including numbers and booleans.

## Query Builder

- Dynamic values live in `__dynamic_posts` (and sibling `__dynamic_*` keys), not in the plain arg. Example: `meta_query: {<_id>: {value: '%current_id%{"context":"default_object"}'}}`.
- Multi-select posts field (`is_multiple`) is stored serialized (`a:2:{i:0;s:2:"12";...}`). Match it with compare `LIKE` and dynamic value `%current_id%{"context":"default_object","before":"\"","after":"\""}` so the ID is wrapped in quotes and `1` does not match `12`.
- A static value like `"%current_id%"` typed into the plain field is not macro-expanded.
- SQL queries: reference tables as `{prefix}posts`, `{prefix}postmeta`. Serialized match: `pm.meta_value LIKE CONCAT('%"', t.ID, '"%')`.
- The Query Builder preview can show 0 results for queries that depend on the current object (`%current_id%`) while the live listing works. Judge on the front end of a real post.

## Relations

- Relation items (which posts are linked) save through admin-ajax action `jet_engine_relations_update_relation_items`; read its nonce from the request the post edit screen fires. Relation settings save from the Relations screen with the full `args` object.
- Relation-to-meta migration (or the reverse): listings, queries, Dynamic Visibility rules and templates that read the old source break silently. List every consumer first, migrate data, switch consumers, verify each page, keep the old data until the user signs off.

## Listing grid

- Carousel is a setting of the Listing Grid widget (`carousel_enabled` plus slides, arrows, dots, autoplay keys). Read the widget's current settings in the editor and change them with `document/elements/settings`; see elementor.md.
- Columns and gaps are per breakpoint (`columns`, `columns_tablet`, `columns_mobile`). Check all three.
- Empty listing: confirm the query returns items on the front end before restyling the grid.

## Jet Tabs and Jet Accordion

- Style through the widget's own style controls in the editor, never CSS on generated class names that change per instance.
- Active and inactive states are separate control groups: set both, then click through every tab or panel in the live page to verify.
- Template-based items render the saved template: edit that template, not the widget.
- Check the first item's initial open state on mobile.

## Hide-if-empty without Dynamic Visibility

- When Dynamic Visibility is unavailable or cannot see the condition, hide the wrapper in CSS with `:has()`: `.wrap:not(:has(.jet-listing-grid__item)) { display: none; }`.
- Put the rule in the site's central CSS snippet and confirm the cache optimiser keeps rules after `:has()` (see cache.md).

## Verify

- CPT or taxonomy slug changes alter permalinks: flush by saving Settings › Permalinks and add redirects for old URLs (see seo.md).
- Load the archive, a single post and one listing that uses the changed field, as a guest with a cache-buster.

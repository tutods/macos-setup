Content runbook: blog posts built from an Elementor template, post updates, live verification, WooCommerce product batches and images.

## New post from a template

1. Write a text spec per post (title, slug, excerpt, SEO title and description, focus keyword, cover, ordered blocks). Validate each block with text-validation.md before building.
2. Build: deep-copy the template post's Elementor tree, give every element a fresh id (`secrets.token_hex(4)`) and rename its local style ids and class references to match, fill the slots from the spec.
3. Fail the build on any text still equal to the template's text, and on structure the template cannot hold (for example a table column count other than the template's). Keep an explicit allowlist for labels meant to stay identical.
4. Grep the output for the template post's URLs and re-point cloned links.
5. Scheduled post: `POST wp/v2/posts` with `status: "future"`, `date` and an explicit `date_gmt` (the site timezone shifts `date` alone), `meta._elementor_data` as a JSON string, `_elementor_edit_mode: "builder"`, SEO meta keys. Read it back with `context=edit` and assert `_elementor_data` round-trips byte for byte.
6. Never `publish-document` on a draft or scheduled post: see elementor.md.
7. `DELETE elementor/v1/cache`, then run the verify script once the post is live.
8. Add contextual links from 2 or more related posts, inside an existing sentence when possible. Add the post to llms.txt (see seo.md).

## Update an existing post

1. Back up `wp/v2/posts/<id>?context=edit`.
2. Patch `meta._elementor_data` by element id on the parsed JSON, or by exact string replace. Match every stored form: `/` and `\/`, and accented characters stored as `à`-style escapes.
3. PUT only `meta`, re-read, compare, clear Elementor cache, verify live.
4. Keep the original publication date. The modified date moves only after a meaningful edit, never to fake freshness.
5. Validate the changed text only.

- Renaming an h2 breaks `#anchor` links built from its text: search posts, pages and products for links to that anchor first.
- A wide table scrolls inside its own wrapper (`overflow-x: auto`, rows with a `min-width`), never the page.

## Verify script

- `curl -s -A '<browser UA>'` with a cache-buster query, 0.6 s between requests.
- Report: status, H1 count (exactly one), `<title>`, meta description, each expected string present, every internal link in the article body returning 200.
- First request on a cold cache can take minutes: send one warm-up request with a long timeout, run the script with `python3 -u` in the background.
- Then check contents-menu anchors, mobile overflow at 390 px and attribution by eye.

## Products (WooCommerce batch)

1. **Research**, parallel agents, no site requests: maker code, EAN, specs from maker or Icecat with sources, official images. Output one `facts.json` per product and a contact sheet the main session looks at.
2. **Copy**, one agent: every product's text into the accepted layout slots, validated per text, repeated-phrase scan across all siblings.
3. **Build**, one serial agent writing to the live site: create as draft, SKU, then GTIN in a separate save and re-read it, images, description, SEO meta. Publish only after the preview renders. Curl the live page.
4. Send open questions to the client in one list.

Cross-check client data before building each item:

- Name, EAN prefix (manufacturer), photo and maker code must agree. Client lists swap EANs, names, photos and codes between items.
- Verify the EAN externally (Icecat by GTIN, maker, a retailer) for that exact model. Unverified: leave GTIN empty and ask for a barcode photo.

## Product images

- Trim and flatten: `magick src -strip -background white -alpha remove -alpha off -fuzz 2% -trim +repage`.
- Pad square on white with a small margin: `-gravity center -extent '%[fx:max(w,h)*1.06]x%[fx:max(w,h)*1.06]'`, then `-resize '1500x1500>'`.
- Encode WebP at rising quality (85, 90, 95, 98) and keep the first with `magick compare -metric PSNR ref out.webp null:` at 42 or more. `cwebp -q <q> -sharp_yuv -m 6` works as the encoder too.
- Log source size, quality, PSNR, output size per file.

## Fact changes propagate

- Any later spec, name or photo change on a product is pushed in the same step to every post citing it: search posts' `_elementor_data` for the product id and model code.
- After a bulk product audit or rename, list every changed fact and sweep the posts.
- Post text names products or categories, never stock-dependent counts ("we have three"): single units sell out and the sentence goes false.

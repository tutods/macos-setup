Social runbook: Instagram and Facebook through Meta Business Suite, asset specs, captions, scheduling by automation, verification, reviews.

Pattern reference: `~/Developer/freelances/gc-wp/scripts/social/` (`meta-schedule-{story,carousel,reel}.cjs`, `carousels.py`, `video-*.py`, `cartao-instagram.py`). They hard-code one account's names, selectors and pixel offsets: copy the approach, rewrite the constants.

## Content split

- Blog posts go to Stories with a link. The feed gets evergreen pieces (videos, carousels) that stay true after a product sells out. Pace: 2 to 3 feed posts a week.
- Weekly plan: `instagram-skills:ig-content-planner`. Slide structure: `ig-carousel-planner`. Caption draft: `ig-caption-writer`. Tags: `ig-hashtag-strategist`. Final pass on every caption and slide: `ig-humanizer`, then text-validation.md.

## Asset specs

- Story 1080x1920 PNG. Carousel 1080x1350 PNG, 6 to 9 slides. Video: 1080x1920 (Reel) plus 1080x1350 (feed), H.264 yuv420p, 30 fps, 15 to 25 s, no audio track (the user adds licensed music in Business Suite), plus a cover PNG per size.
- Safe zones on 9:16: key text stays out of the top 250 px and bottom 400 px.
- Draw with Pillow at 2x and downscale with `LANCZOS` for clean edges.
- Video: pipe Pillow frames to ffmpeg: `ffmpeg -y -f rawvideo -pix_fmt rgb24 -s WxH -r 30 -i - -c:v libx264 -preset slow -crf 18 -pix_fmt yuv420p -movflags +faststart -an out.mp4`, write `frame.convert('RGB').tobytes()` per frame, close stdin, assert exit 0.
- Look at every slide and sampled video frames before delivering: overlaps, clipped text, decoration crossing text, wrong counts.
- Images: the site's official product files only. No AI images, no stock photos of people.

## Copy rules

- No prices, stock counts or discount figures. Category wording over single units; a named product only when in stock on the posting day.
- Facts only from live site pages and published guides.
- Hook in the first 125 characters of the caption and the first 2 seconds of a video.
- One concrete action per post (send a message, save, read the guide).
- Every caption, slide text, alt and first comment passes text-validation.md, plus a repeated-phrase check against earlier pieces.

## Caption file

Each piece ships in its own folder with a `legenda.txt` in 7 sections, `=====` rulers between them:

1. Instagram caption (hook under 125 chars, ends pointing to the link in bio).
2. Facebook caption with the clickable UTM link, then a `-----` ruler and the Instagram bio or sticker link.
3. Keywords used.
4. Hashtags (8 to 12).
5. Alt text per slide, one `NN: text` line each (the carousel script reads these and requires one per slide).
6. Optional first comment.
7. Suggested time, marked as untested until account stats exist.

UTM: `?utm_source=instagram|facebook&utm_medium=social|video|story&utm_campaign=<slug>`.

## Browser for publishing

1. Start real Chrome: `--incognito --user-data-dir="$(mktemp -d)" --remote-debugging-port=<port> --remote-debugging-address=127.0.0.1`.
2. The user logs into Business Suite by hand, every session. Never save the login, cookies or a persistent profile.
3. Install `playwright-core` with pnpm in a scratch folder, run node from there, attach with `chromium.connectOverCDP('http://127.0.0.1:<port>')` and pick the existing `facebook.com` page.
4. Afterwards close the window and delete the user-data folder.

## Scheduling by automation

- Upload: `const c = page.waitForEvent('filechooser'); <JS-click the add-media button>; (await c).setFiles(paths)`.
- Captions: dispatch a synthetic `ClipboardEvent('paste')` with a `DataTransfer` holding the text into the contenteditable. Typing triggers hashtag autocomplete. Read the editor's `innerText` back and compare.
- Precheck before the final "Agendar" (Schedule) click: target account, date, both time fields, link present, alts kept after apply. Throw on any mismatch.
- `NOCLICK=1` stops before the final click. Run one item with it, look at the screenshot, then run the batch.
- Each blog story is scheduled twice as separate stories: Instagram with a link sticker, Facebook with the composer's link option and its own UTM, no sticker.
- Story toggle dialog on Reels: pick "Partilhar esta história" (share this story), never "Partilhar sempre" (always share, page-wide).
- Carousel alt text is per slide in the composer's photo editor; set all, re-read all.

## Verify

1. Before proposing or scheduling anything, read Meta's own lists: `latest/posts/published_posts`, `latest/posts/scheduled_posts`, `latest/posts/scheduled_stories`. Meta beats the local calendar.
2. After scheduling, open each item: watch the video and read the caption. A list entry can carry another piece's caption or video.
3. Check the linked page is live and the main product still in stock on the sharing day.

Gotchas:

- Deleting a scheduled Instagram story can fail from automation: ask the user to delete it by hand.
- A scheduled Facebook story can show as a blank tile in the planner.
- "Erro ao publicar" on a list row can be a stale label: open the live post before re-posting.
- Meta's timezone label can read another zone with the same clock: compare the shown time, not the label.
- Story images with counts ("four models") go stale when the guide changes: check the image text against the live post.
- Drag-placed stickers drift between runs: measure the placement from a screenshot and fail if off target.

## Reviews

- Never incentivise a review. Ask every customer, never only the happy ones.
- Google review link: `https://search.google.com/local/writereview?placeid=<PLACE_ID>`.
- Quotes on site or in stories are verbatim, first name plus initial, from reviews that look genuine.
- Review ask lives in the WooCommerce "Completed order" email's additional content; a separate manual review-request email is an extra, sent by hand, never on a timer.
- Print card: `qrencode -t SVG -m 1 -o - <url>`, base64 into an `<img>` in an A6 HTML page (`@page {size: 105mm 148mm; margin: 0}`, `print-color-adjust: exact`), print to PDF from Chrome. Add a UTM to the URL to count scans.

---
name: optimize-images
description: Optimize one or several images for the web — strip all metadata, resize so the longest side is at most 1500px (keep aspect ratio, only shrinks if larger), and convert to WebP. Use when the user says "optimize image(s)", "compress these images", "convert to webp", "strip metadata and resize", "otimizar imagens", or hands over raw photos/screenshots/exports that need to ship on a site or in an app.
---

# Optimize images

Turns raw images (camera photos, Figma exports, screenshots) into web-ready WebP: no
metadata, capped dimensions, aggressively compressed. Non-destructive — writes
`name.webp` next to `name.jpg`, never touches or deletes the original.

## When to use

Any time images need to go into a site, app, or repo and haven't been through this
pipeline yet — asset prep before a build, cleaning up a batch of exports, shrinking
oversized photos before upload.

## Pipeline

1. `magick` resizes (only if larger than the cap, aspect ratio preserved) and strips
   all metadata (EXIF, ICC profiles, comments, GPS) in one pass.
2. `cwebp` encodes the result to WebP at high compression effort, with `-metadata none`
   as a second guarantee no metadata survives.

Both tools are already installed via nix (`imagemagick`, `libwebp`).

## Run it

```bash
optimize-images.sh photo.jpg
optimize-images.sh img1.png img2.jpg img3.tif
optimize-images.sh ./raw-assets/*.jpg
optimize-images.sh ./raw-assets/          # directory: picks up jpg/jpeg/png/tif/tiff/bmp inside
```

The script lives at `scripts/optimize-images.sh` in this skill's directory — call it by
that path, or add the skill's `scripts/` dir to `PATH` if invoking it repeatedly.

Overrides via env vars:

```bash
MAX_DIM=2000 QUALITY=90 optimize-images.sh hero.png   # bigger cap, higher quality
```

- `MAX_DIM` — longest-side cap in px, default `1500`.
- `QUALITY` — cwebp quality (0–100), default `82`.

## One-off inline recipe (no script)

For a single image without the script:

```bash
magick in.jpg -resize "1500x1500>" -strip /tmp/tmp.png
cwebp -q 82 -m 6 -metadata none /tmp/tmp.png -o out.webp
rm /tmp/tmp.png
```

`-resize "1500x1500>"` — the trailing `>` means shrink-only, never upscale, aspect kept.

## Notes / limits

- Inputs already `.webp` are skipped (output name would collide with the source).
- Still images only — animated GIFs won't animate through `cwebp` this way; skip those
  or handle separately (`gif2webp` for animated).
- Originals are always kept. Deleting them, if wanted, is a separate manual step.

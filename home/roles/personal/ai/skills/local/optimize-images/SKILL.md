---
name: optimize-images
description: Optimize one or several images for the web, strip all metadata, resize so the longest side is at most 1500px (keep aspect ratio, only shrinks if larger), and convert to WebP. Use when the user says "optimize image(s)", "compress these images", "convert to webp", "strip metadata and resize", "otimizar imagens", or hands over raw photos/screenshots/exports that need to ship on a site or in an app.
---

# Optimize images

Turns raw images (camera photos, Figma exports, screenshots) into web-ready WebP: no metadata, capped dimensions, aggressively compressed. Non-destructive, writes `name.webp` next to `name.jpg`, never touches or deletes the original.

## Pipeline

1. `magick` resizes (only if larger than the cap, aspect ratio preserved) and strips all metadata (EXIF, ICC profiles, comments, GPS) in one pass.
2. `cwebp` encodes the result to WebP at high compression effort, with `-metadata none` as a second guarantee no metadata survives.

Both tools are already installed via nix (`imagemagick`, `libwebp`).

## Run it

The script is `scripts/optimize-images.sh` inside this skill's directory, `~/.claude/skills/optimize-images/scripts/optimize-images.sh` once deployed. It handles one file, a list, a glob, or a directory:

```bash
bash ~/.claude/skills/optimize-images/scripts/optimize-images.sh photo.jpg
bash ~/.claude/skills/optimize-images/scripts/optimize-images.sh img1.png img2.jpg
bash ~/.claude/skills/optimize-images/scripts/optimize-images.sh ./raw-assets/
```

A directory argument picks up jpg/jpeg/png/tif/tiff/bmp inside it. Two env-var overrides: `MAX_DIM` (longest-side cap in px, default `1500`) and `QUALITY` (cwebp quality 0–100, default `82`).

```bash
MAX_DIM=2000 QUALITY=90 bash .../optimize-images.sh hero.png
```

## Notes / limits

- Inputs already `.webp` are skipped (output name would collide with the source).
- Still images only, animated GIFs won't animate through `cwebp` this way; skip those or handle separately (`gif2webp` for animated).
- Originals are always kept. Deleting them, if wanted, is a separate manual step.

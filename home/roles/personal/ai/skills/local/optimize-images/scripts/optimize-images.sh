#!/usr/bin/env bash
set -euo pipefail

# Optimize images: strip metadata, cap longest side at MAX_DIM (aspect kept, only
# shrinks), convert to WebP. Writes name.webp next to name.ext — never touches or
# deletes the original.
#
# Usage:
#   optimize-images.sh file1.jpg file2.png ...
#   optimize-images.sh ./some-dir/
#
# Env overrides:
#   MAX_DIM  - longest-side cap in px (default 1500)
#   QUALITY  - cwebp quality 0-100 (default 82)

MAX_DIM="${MAX_DIM:-1500}"
QUALITY="${QUALITY:-82}"

if [[ $# -eq 0 ]]; then
  echo "Usage: $(basename "$0") <image|dir> [image|dir ...]" >&2
  exit 1
fi

for tool in magick cwebp; do
  if ! command -v "$tool" >/dev/null 2>&1; then
    echo "error: required tool '$tool' not found on PATH" >&2
    exit 1
  fi
done

# Expand directory arguments into the raster files they contain.
files=()
for arg in "$@"; do
  if [[ -d "$arg" ]]; then
    while IFS= read -r -d '' found; do
      files+=("$found")
    done < <(find "$arg" -maxdepth 1 -type f \( \
      -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \
      -o -iname '*.tif' -o -iname '*.tiff' -o -iname '*.bmp' \
      \) -print0)
  else
    files+=("$arg")
  fi
done

if [[ ${#files[@]} -eq 0 ]]; then
  echo "no images found" >&2
  exit 1
fi

for src in "${files[@]}"; do
  if [[ ! -f "$src" ]]; then
    echo "skip: $src (not a file)" >&2
    continue
  fi

  ext="${src##*.}"
  if [[ "${ext,,}" == "webp" ]]; then
    echo "skip: $src (already webp)"
    continue
  fi

  dest="${src%.*}.webp"
  tmp="$(mktemp -t optimize-images).png"

  magick "$src" -resize "${MAX_DIM}x${MAX_DIM}>" -strip "$tmp"
  cwebp -q "$QUALITY" -m 6 -metadata none "$tmp" -o "$dest" >/dev/null 2>&1
  rm -f "$tmp"

  before=$(du -h "$src" | cut -f1)
  after=$(du -h "$dest" | cut -f1)
  echo "$src ($before) -> $dest ($after)"
done

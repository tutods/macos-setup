# Fish Shell Code Signing Fix

## Problem

On macOS (especially Apple Silicon), running `fish` results in:

```
zsh: killed     fish
```

This happens because macOS **kills any binary with an invalid code signature**. Nix store operations (builds, garbage collection, optimizations) can invalidate the code signatures on binaries in `/nix/store`, even though they're read-only. When macOS detects an invalid signature, it sends `SIGKILL` immediately — no error message, no crash log, just `killed`.

## How to Diagnose

```bash
# Check if the signature is valid
codesign -v $(which fish) 2>&1

# Expected bad output:
# /etc/profiles/per-user/tutods/bin/fish: invalid signature (code or signature have been modified)

# Expected good output:
# (no output = valid signature)
```

## Quick Fix

```bash
sudo codesign --force --sign - $(which fish)
```

## Automated Fix

A script is included at `scripts/fix-fish-codesign.sh` that checks and re-signs if needed:

```bash
./scripts/fix-fish-codesign.sh
```

## Prevention

The `mkHost.nix` config includes an activation script that automatically re-signs fish after every `darwin-rebuild switch`:

```nix
system.activationScripts.fixFishCodesign.text = ''
  fish_bin="/etc/profiles/per-user/${username}/bin/fish"
  if [ -x "$fish_bin" ]; then
    if ! codesign -v "$fish_bin" 2>/dev/null; then
      echo "Re-signing fish binary (invalid code signature detected)"
      codesign --force --sign - "$fish_bin" 2>/dev/null || true
    fi
  fi
'';
```

This runs as root during every rebuild, so code signing issues are fixed automatically.

## Root Cause

- Nix builds create new store paths with valid signatures
- Occasionally, macOS runtime signature checks fail on Nix binaries (especially after `/nix/store` GC or optimization)
- Apple Silicon enforces code signing more strictly than Intel Macs
- The `killed` message (SIGKILL) is macOS enforcing code signing policy — it's not a crash, it's an execution prevention

## If the Fix Doesn't Work

1. Rebuild the entire config: `./nix.sh macbook --force`
2. Repair the Nix store: `sudo nix store repair`
3. Full re-sign of all Nix binaries (nuclear option):
   ```bash
   find /nix/store -maxdepth 1 -type f -perm -u+x -exec codesign --force --sign - {} \; 2>/dev/null
   ```
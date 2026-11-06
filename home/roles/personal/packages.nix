# Personal-machine-only user tools. These are role packages, not system
# packages: docs/nix-conventions.md places personal-only tools here.
{
  pkgs,
  pkgsUnstable,
  ...
}: let
  # Temporary override: nixpkgs-unstable's opencode 1.18.30 crashes on every
  # prompt. See opencode-pinned.nix. Restore pkgsUnstable.opencode below once
  # nixpkgs ships > 1.18.30.
  opencodePinned = pkgsUnstable.callPackage ./opencode-pinned.nix {};
in {
  # Nix owns doppler's version, so its update notice has no action to offer.
  # A flag, not DOPPLER_ENABLE_VERSION_CHECK: the env var prints its own notice.
  home.shellAliases.doppler = "doppler --no-check-version";

  home.packages =
    (with pkgs; [
      terraform
      nixd
      # Claude Code's typescript-lsp plugin needs it on PATH; editors and opencode bundle their own.
      typescript-language-server
      # GUI app kept from nixpkgs: every Homebrew qbittorrent cask
      # (qbittorrent, qbittorrent@lt20, c0re100-qbittorrent) was disabled
      # on 2026-09-01 for failing the macOS Gatekeeper check, and a
      # disabled cask fails `brew install`, breaking the deploy.
      qbittorrent
    ])
    ++ [
      # fast-moving AI CLIs, stable lags too far — same rationale as claude-code
      opencodePinned
      pkgsUnstable.codex
      # stable's minor-version freeze leaves it behind every Doppler release
      pkgsUnstable.doppler
      (pkgs.callPackage ./lightroom-cli.nix {})
    ];
}

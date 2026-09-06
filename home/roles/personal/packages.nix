# Personal-machine-only user tools. These are role packages, not system
# packages: docs/nix-conventions.md places personal-only tools here.
{
  pkgs,
  pkgsUnstable,
  ...
}: {
  home.packages =
    (with pkgs; [
      doppler
      terraform
      nixd
      # GUI app kept from nixpkgs: every Homebrew qbittorrent cask
      # (qbittorrent, qbittorrent@lt20, c0re100-qbittorrent) was disabled
      # on 2026-09-01 for failing the macOS Gatekeeper check, and a
      # disabled cask fails `brew install`, breaking the deploy.
      qbittorrent
    ])
    ++ [
      # fast-moving AI CLI, stable lags too far — same rationale as claude-code
      pkgsUnstable.opencode
    ];
}

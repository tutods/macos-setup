{
  pkgs,
  pkgsUnstable,
  ...
}: {
  environment.systemPackages = [
    # fast-moving, stable lags too far (docs/nix-conventions.md)
    pkgsUnstable.claude-code
    # token-reducing CLI proxy for the Claude Code hook it powers; track upstream closely
    pkgsUnstable.rtk
    pkgs.pipx
    # worktrunk (`wt`) comes from Homebrew, not here: nixpkgs would compile it
    # from Rust source and two of its tests fail in the darwin sandbox.
  ];
}

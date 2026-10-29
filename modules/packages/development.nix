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
    # doCheck = false: on the stable-darwin branch tip pipx often has no cache
    # entry and builds from source, where its test suite fails on cosmetic
    # packaging-version skew ("name@ url" vs "name @ url" assertions). The
    # tests validate upstream pipx, not this config. Same override in
    # home/common/ai/init.nix — keep them in sync.
    (pkgs.pipx.overridePythonAttrs (_: {doCheck = false;}))
    # worktrunk (`wt`) comes from Homebrew, not here: nixpkgs would compile it
    # from Rust source and two of its tests fail in the darwin sandbox.
  ];

  # nixpkgs wraps claude-code with `--set-default CLAUDE_CODE_CERT_STORE
  # system`, but the native binary cannot read the macOS trust store, so it
  # is left with no CAs on darwin (nixpkgs#579204, fix PR#579756 pending).
  # --set-default yields to a preset variable; `bundled,system` is claude's
  # own default. Drop once the pinned nixpkgs carries the darwin fix.
  environment.variables.CLAUDE_CODE_CERT_STORE = "bundled,system";
}

{pkgsUnstable, ...}: {
  environment.systemPackages = with pkgsUnstable; [
    claude-code
    rtk # compresses CLI output before it reaches the context window; hook in home/common/ai/settings.nix
    (pipx.overridePythonAttrs {doCheck = false;})
    # worktrunk (`wt`) comes from Homebrew, not here: nixpkgs would compile it
    # from Rust source and two of its tests fail in the darwin sandbox.
  ];
}

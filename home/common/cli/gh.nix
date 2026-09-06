{...}: {
  programs.gh = {
    enable = true;
    # gh-copilot was archived upstream and removed from nixpkgs 26.05; its
    # suggested successor (github-copilot-cli) is a standalone binary, not a
    # gh extension, so it does not belong here.
    extensions = [];
  };
}

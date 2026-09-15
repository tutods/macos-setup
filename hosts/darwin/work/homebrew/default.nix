{...}: {
  homebrew = {
    casks = [
      "brave-browser"
      "gcloud-cli"
      "slack"
    ];

    brews = [
      "k9s"
    ];

    # `trusted: true` on a `brew` line is Homebrew Bundle syntax nix-darwin's
    # typed `taps`/`brews` options have no equivalent for (see the shared
    # homebrew module's extraConfig for the same pattern on a cask).
    extraConfig = ''
      brew "atlassian/acli/acli", trusted: true
    '';
  };
}

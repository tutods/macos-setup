{...}: {
  # shellInit, not interactiveShellInit: gcloud must exist for scripts and
  # `fish -c` too. --append keeps Homebrew-managed bins behind every
  # Nix-managed PATH entry.
  programs.fish.shellInit = ''
    fish_add_path --append --path /opt/homebrew/share/google-cloud-sdk/bin
  '';
}

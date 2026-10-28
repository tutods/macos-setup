{...}: {
  # shellInit, not interactiveShellInit: gcloud must exist for scripts and
  # `fish -c` too. --append keeps Homebrew-managed bins behind every
  # Nix-managed PATH entry.
  programs.fish.shellInit = ''
    fish_add_path --append --path /opt/homebrew/share/google-cloud-sdk/bin

    # Node ignores the macOS keychain, so the corporate TLS-inspection root CA needs this.
    if test -f ~/.config/certs/corp-bundle.pem
      set -gx NODE_EXTRA_CA_CERTS ~/.config/certs/corp-bundle.pem
    end
  '';
}

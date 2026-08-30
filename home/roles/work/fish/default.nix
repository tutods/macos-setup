{...}: {
  programs.fish.interactiveShellInit = ''
    fish_add_path --path /opt/homebrew/share/google-cloud-sdk/bin
  '';
}

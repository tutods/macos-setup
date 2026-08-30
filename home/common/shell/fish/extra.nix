{
  programs.zoxide = {
    enable = true;
    enableFishIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  programs.eza = {
    enable = true;
    enableFishIntegration = true;
    icons = "auto";
    git = true;
    extraOptions = [
      "--group-directories-first"
      "--header"
      "--color=auto"
    ];
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
    defaultOptions = [
      "--height 40%"
      "--layout=reverse"
      "--border"
    ];
    # eza preview for the cd widget (Alt+C). fzf's fish integration reads
    # this; the old `set fzf_preview_dir_cmd` belonged to the uninstalled
    # fzf.fish plugin and was dead.
    changeDirWidgetOptions = ["--preview 'eza --all --color=always {}'"];
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
    stdlib = ''
      use_fnm() {
        fnm use --install-if-missing --silent-if-unchanged
      }
    '';
  };
}

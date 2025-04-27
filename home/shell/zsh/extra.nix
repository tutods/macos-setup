{
  programs.zoxide = {
    enable = true;
    enableZshIntegration = true;
    options = [
      "--cmd cd"
    ];
  };

  fzf = {
    enable = true;
    enableZshIntegration = true;
  };
}
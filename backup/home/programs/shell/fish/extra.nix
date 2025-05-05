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
      "--color=always"
      "--icons"
    ];
  };

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };
}
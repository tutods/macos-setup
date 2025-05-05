{ pkgs, ... }:

{
  programs.fish.plugins = [
    # fzf.fish - Powerful fzf integration for directory navigation with tab completion
    {
      name = "fzf.fish";
      src = pkgs.fetchFromGitHub {
        owner = "PatrickF1";
        repo = "fzf.fish";
        rev = "v9.2";  # Use a specific version for stability
        sha256 = "sha256-XmRGe39O3xXmTvfawwT2mCwLIyXOlQm7f40mH5tzz+s=";
      };
    }
    {
      name = "plugin-git";
      src = pkgs.fishPlugins.plugin-git.src;
    }
    {
      name = "pisces";
      src = pkgs.fishPlugins.pisces.src;
    }
    # zoxide plugin for Fish
    {
      name = "zoxide";
      src = pkgs.fetchFromGitHub {
        owner = "kidonng";
        repo = "zoxide.fish";
        rev = "fd17bbf41d821eeddd33c6fe883faa7a48fb7230"; # Latest commit as of May 2023
        sha256 = "sha256-xAGDQ0Wd5qFcSQQEAUu0hHYeXHiEjmzmRFbGjhNL/9I=";
      };
    }
  ];
}
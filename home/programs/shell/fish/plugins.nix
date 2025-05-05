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
  ];
}
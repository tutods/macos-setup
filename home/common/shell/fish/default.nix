{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./extra.nix];

  xdg.configFile."fish/completions/fnm.fish".source = ./fnm-completions.fish;

  programs.fish = {
    enable = true;
    shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;

    shellInit = ''
      # Project directory (used in fish functions like fzf_jump, node_clean)
      set -gx PROJECT_DIR "${config.home.devDir}"

      if test -f ~/.config/fish/secrets.fish
        source ~/.config/fish/secrets.fish
      end
    '';

    plugins = [
      {
        name = "pisces";
        src = pkgs.fishPlugins.pisces.src;
      }
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
    ];

    interactiveShellInit = ''
      bind \ew backward-kill-line

      set fzf_preview_dir_cmd eza --all --color=always

      fnm env --use-on-cd --shell fish --corepack-enabled --resolve-engines | source
    '';

    shellInit = ''
      set -gx PROJECT_DIR "${config.home.devDir}"

      if test -f ~/.config/fish/secrets.fish
        source ~/.config/fish/secrets.fish
      end

      if not contains "$HOME/.local/bin" $fish_user_paths
        set -U fish_user_paths $HOME/.local/bin $fish_user_paths
      end
    '';
  };
}

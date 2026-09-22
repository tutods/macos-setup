{
  config,
  pkgs,
  lib,
  ...
}: {
  imports = [./extra.nix];

  xdg.configFile."fish/completions/fnm.fish".source = ./fnm-completions.fish;

  # fnm's default alias is a stable symlink (unlike its per-shell multishell
  # dir below, torn down when that shell exits), so anything spawned outside
  # an fnm-initialized shell — Claude Code plugin hooks included — still
  # finds `node`. Listed after `.local/bin` so an active project version from
  # `fnm env`/`fnm use` in interactiveShellInit still shadows it.
  home.sessionPath = ["$HOME/.local/bin" "$HOME/.local/share/fnm/aliases/default/bin"];

  programs.fish = {
    enable = true;
    shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;

    shellInit = ''
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
      # Migration: erase the stale universal var once; PATH is declarative now.
      if set -qU fish_user_paths
        set -eU fish_user_paths
      end

      # fish 4.3 moved fish_key_bindings from universal to global scope and
      # drops a conf.d/fish_frozen_key_bindings.fish to erase the old universal
      # on every startup. Only one fish version exists here (nixpkgs pins it),
      # so the erase can happen here instead and that file can be deleted; we
      # never set fish_key_bindings, the default bindings are what we want.
      if set -qU fish_key_bindings
        set -eU fish_key_bindings
      end

      bind \ew backward-kill-line

      # Guarded: on a fresh deploy the new generation's PATH is not active in
      # the shell that re-sources this, and worktrunk (brew) activates after
      # the fish rebuild, so both binaries can be transiently absent.
      if command -q fnm
        fnm env --shell fish --use-on-cd --corepack-enabled --resolve-engines | source
      end

      # `wt switch` changes directory, so it needs a shell function. Declared
      # here rather than via `wt config shell install`, which rewrites
      # ~/.config/fish/conf.d/wt.fish and fights this file.
      if command -q wt
        wt config shell init fish | source
      end
    '';
  };
}

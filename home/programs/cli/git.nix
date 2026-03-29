{ ... }:

# Shared git configuration for all users.
# Identity (name + email) is NOT stored here — it lives in ~/.config/git/private
# on each machine and is never committed to this repo.
# See docs/private-git-config.md for setup instructions.
{
  programs.delta = {
    enable = true;
    options = {
      navigate    = true;   # n/N to move between diff sections
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "Catppuccin Mocha";
      dark         = true;
    };
  };

  programs.git = {
    enable = true;
    includes = [{ path = "~/.config/git/private"; }];
    settings.extraConfig = {
      init.defaultBranch   = "main";
      push.autoSetupRemote = true;
      pull.rebase          = true;
      merge.conflictstyle  = "diff3";  # delta works best with diff3
      diff.colorMoved      = "default";
    };
    lfs.enable = true;
  };
}

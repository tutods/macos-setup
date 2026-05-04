{...}:
# Shared git configuration for all users.
# Identity (name + email) is NOT stored here — it lives in ~/.config/git/private
# on each machine and is never committed to this repo.
# See docs/private-git-config.md for setup instructions.
{
  programs.delta = {
    enable = true;
    options = {
      navigate = true;
      side-by-side = true;
      line-numbers = true;
      syntax-theme = "Catppuccin Mocha";
      dark = true;
      interactive = true;
    };
  };

  programs.git = {
    enable = true;
    includes = [{path = "~/.config/git/private";}];
    settings = {
      init.defaultBranch = "main";
      push.autoSetupRemote = true;
      pull.rebase = true;
      merge.conflictstyle = "diff3";
      diff.colorMoved = "default";
      fetch.prune = true;
      fetch.pruneTags = true;
      rerere.enabled = true;
      commit.verbose = true;
      rebase.autoStash = true;
      core.autocrlf = "input";
    };
    lfs.enable = true;
  };
}

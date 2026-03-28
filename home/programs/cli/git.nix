{ ... }:

# Shared git configuration for all users.
# Identity (name + email) is NOT stored here — it lives in ~/.config/git/private
# on each machine and is never committed to this repo.
# See docs/private-git-config.md for setup instructions.
{
  programs.diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;
  };

  programs.git = {
    enable = true;
    includes = [{ path = "~/.config/git/private"; }];
    settings.extraConfig = {
      init.defaultBranch  = "main";
      push.autoSetupRemote = true;
      pull.rebase          = true;
    };
    lfs.enable = true;
  };
}

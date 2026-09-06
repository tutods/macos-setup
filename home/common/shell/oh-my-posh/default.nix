{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.oh-my-posh = {
    enable = true;
    # HM's fish integration lands in shellInit, which also runs for every
    # non-interactive `fish -c` (~45ms each). Keep it off and init only in
    # interactive shells below.
    enableFishIntegration = false;
    settings = pkgs.lib.importTOML ./base.toml;
  };

  # Same line HM's oh-my-posh module generates for fish (settings != {} means
  # it points --config at the generated $XDG_CONFIG_HOME/oh-my-posh/config.json),
  # just placed in interactiveShellInit instead of shellInit.
  programs.fish.interactiveShellInit = ''
    ${lib.getExe config.programs.oh-my-posh.package} init fish --config ${config.xdg.configHome}/oh-my-posh/config.json | source
  '';
}

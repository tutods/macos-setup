{
  config,
  lib,
  ...
}: {
  xdg.configFile."zed/keymap.json".source = ./keymap.json;

  home.activation.zedSeedSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run install -m 0644 ${./settings.json} "${config.xdg.configHome}/zed/settings.json"
  '';
}

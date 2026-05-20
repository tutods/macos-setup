{
  config,
  pkgs,
  lib,
  ...
}: {
  xdg.configFile."zed/keymap.json" = {
    source = ./keymap.json;
  };

  home.activation.zedSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="${config.xdg.configHome}/zed/settings.json"
    if [ ! -f "$target" ]; then
      echo "↣ seed zed settings (one-time)"
      mkdir -p "$(dirname "$target")"
      cp ${./settings.json} "$target"
    fi
  '';
}

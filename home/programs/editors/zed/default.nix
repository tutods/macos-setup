{config, ...}: {
  xdg.configFile."zed/settings.json" = {
    source = ./settings.json;
  };
  xdg.configFile."zed/keymap.json" = {
    source = ./settings.json;
  };
}

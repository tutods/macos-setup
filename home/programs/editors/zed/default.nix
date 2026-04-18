{config, ...}: {
  xdg.configFile."zed/settings.json" = {
    source = ./settings.json;
  };
}
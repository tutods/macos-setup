{config, ...}: {
  home.file."Library/Application Support/Zed/settings.json" = {
    source = ./settings.json;
  };
  home.file."Library/Application Support/Zed/keymap.json" = {
    source = ./keymap.json;
  };
}

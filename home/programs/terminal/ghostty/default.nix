{config, ...}: {
  xdg.configFile."ghostty/config" = {
    source = ./config;
  };
  xdg.configFile."ghostty/themes/catppuccin-mocha" = {
    source = ./themes/catppuccin-mocha;
  };
}

{pkgs, ...}: {
  programs.bat = {
    enable = true;
    config = {
      theme = "Catppuccin Mocha";
      style = "full";
      map-syntax = [
        ".ignore:Git Ignore"
        ".gitignore:Git Ignore"
        "*.conf:INI"
      ];
    };
    extraPackages = with pkgs.bat-extras; [batpipe batgrep batdiff];
  };
}

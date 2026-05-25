{
  config,
  lib,
  ...
}: {
  # Extensions (install manually via Cmd+Shift+X — Nix cannot manage Zed extensions yet):
  #
  # Languages & Syntax
  #   html               https://zed.dev/extensions/html
  #   toml               https://zed.dev/extensions/toml
  #   nix                https://zed.dev/extensions/nix
  #   dockerfile         https://zed.dev/extensions/dockerfile
  #   docker-compose     https://zed.dev/extensions/docker-compose
  #   mermaid            https://zed.dev/extensions/mermaid
  #   csv                https://zed.dev/extensions/csv
  #   prisma             https://zed.dev/extensions/prisma
  #   env-file           https://zed.dev/extensions/env-file
  #   xml                https://zed.dev/extensions/xml
  #
  # Tooling
  #   biome              https://zed.dev/extensions/biome
  #   emmet              https://zed.dev/extensions/emmet
  #   git-firefly        https://zed.dev/extensions/git-firefly
  #   mcp-server-context7 https://zed.dev/extensions/mcp-server-context7
  #   color-highlight    https://zed.dev/extensions/color-highlight
  #   symbols            https://zed.dev/extensions/symbols
  #   codebook           https://zed.dev/extensions/codebook  (spell check in comments/strings)
  #
  # Themes & Icons
  #   rose-pine-theme    https://zed.dev/extensions/rose-pine-theme
  #   github-theme       https://zed.dev/extensions/github-theme
  #   catppuccin         https://zed.dev/extensions/catppuccin
  #   min-theme          https://zed.dev/extensions/min-theme
  #   catppuccin-icons   https://zed.dev/extensions/catppuccin-icons
  #   charmed-icons      https://zed.dev/extensions/charmed-icons

  xdg.configFile."zed/keymap.json".source = ./keymap.json;

  home.activation.zedSeedSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    run install -m 0644 ${./settings.json} "${config.xdg.configHome}/zed/settings.json"
  '';
}

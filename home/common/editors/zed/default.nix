{
  config,
  lib,
  pkgs,
  ...
}: {
  # settings.json configures alejandra as Zed's external Nix formatter with
  # format_on_save, so the binary must exist on PATH for every user.
  home.packages = [pkgs.alejandra];

  # Extensions (install manually via Cmd+Shift+X, Nix cannot manage Zed extensions yet):
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

  # Seed-once: Zed writes its own changes back to these files (see CLAUDE.md),
  # settings.json via the settings UI and keymap.json via the keymap editor,
  # so never overwrite an existing copy.
  home.activation.zedSeedSettings = lib.hm.dag.entryAfter ["writeBoundary"] ''
    if [ ! -f "${config.xdg.configHome}/zed/settings.json" ]; then
      run mkdir -p "${config.xdg.configHome}/zed"
      run install -m 0644 ${./settings.json} "${config.xdg.configHome}/zed/settings.json"
    fi
    if [ ! -f "${config.xdg.configHome}/zed/keymap.json" ]; then
      run mkdir -p "${config.xdg.configHome}/zed"
      run install -m 0644 ${./keymap.json} "${config.xdg.configHome}/zed/keymap.json"
    fi
  '';
}

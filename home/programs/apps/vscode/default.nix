{ config, lib, pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      userSettings = pkgs.lib.importJSON ./settings.json;
      keybindings = pkgs.lib.importJSON ./keybindings.json;

      # The extensions commented didn't work
      extensions = with pkgs; [
        vscode-extensions.redhat.vscode-yaml
        # vscode-extensions.chakrounanas.turbo-console-log
        vscode-extensions.meganrogge.template-string-converter
        vscode-extensions.bradlc.vscode-tailwindcss
        vscode-extensions.foxundermoon.shell-format
        vscode-extensions.alefragnani.project-manager
        vscode-extensions.yoavbls.pretty-ts-errors
        # vscode-extensions.wallabyjs.console-ninjarors
        # vscode-extensions.streetsidesoftware.code-spell-checker-portuguese
        vscode-extensions.christian-kohler.npm-intellisense
        vscode-extensions.bbenoist.nix
        vscode-extensions.unifiedjs.vscode-mdx
        vscode-extensions.bierner.github-markdown-preview
        vscode-extensions.yzhang.markdown-all-in-one
        vscode-extensions.github.github-vscode-theme
        # vscode-extensions.miguelsolorio.fluent-icons
        vscode-extensions.usernamehw.errorlens
        vscode-extensions.ms-azuretools.vscode-docker
        vscode-extensions.streetsidesoftware.code-spell-checker
        # vscode-extensions.maximus136.change-string-case
        vscode-extensions.catppuccin.catppuccin-vsc-icons
        vscode-extensions.catppuccin.catppuccin-vsc
        vscode-extensions.biomejs.biome
        vscode-extensions.aaron-bond.better-comments
        vscode-extensions.formulahendry.auto-rename-tag
        vscode-extensions.formulahendry.auto-close-tag
        # vscode-extensions.aliariff.auto-add-brackets
        # vscode-extensions.pflannery.vscode-versionlens
        vscode-extensions.eamodio.gitlens
      ];
    };
  };
}
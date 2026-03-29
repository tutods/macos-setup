{ config, lib, pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      userSettings = pkgs.lib.importJSON ./settings.json;
      keybindings = pkgs.lib.importJSON ./keybindings.json;

      # Extensions available in nixpkgs — managed declaratively.
      # Extensions NOT in nixpkgs are installed via install-vscode-extensions.sh.
      extensions = with pkgs; [
        vscode-extensions.aaron-bond.better-comments
        vscode-extensions.adpyke.codesnap
        vscode-extensions.alefragnani.project-manager
        vscode-extensions.bbenoist.nix
        vscode-extensions.bierner.color-info
        vscode-extensions.bierner.github-markdown-preview
        vscode-extensions.biomejs.biome
        vscode-extensions.bradlc.vscode-tailwindcss
        vscode-extensions.catppuccin.catppuccin-vsc
        vscode-extensions.catppuccin.catppuccin-vsc-icons
        vscode-extensions.christian-kohler.npm-intellisense
        vscode-extensions.eamodio.gitlens
        vscode-extensions.enkia.tokyo-night
        vscode-extensions.formulahendry.auto-close-tag
        vscode-extensions.formulahendry.auto-rename-tag
        vscode-extensions.foxundermoon.shell-format
        vscode-extensions.github.github-vscode-theme
        vscode-extensions.jock.svg
        vscode-extensions.meganrogge.template-string-converter
        vscode-extensions.ms-azuretools.vscode-docker
        vscode-extensions.mvllow.rose-pine
        vscode-extensions.redhat.vscode-yaml
        vscode-extensions.streetsidesoftware.code-spell-checker
        vscode-extensions.teabyii.ayu
        vscode-extensions.unifiedjs.vscode-mdx
        vscode-extensions.usernamehw.errorlens
        vscode-extensions.yoavbls.pretty-ts-errors
        vscode-extensions.yzhang.markdown-all-in-one
      ];
    };
  };
}

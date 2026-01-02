{ config, lib, pkgs, ... }:

{
  programs.vscode = {
    enable = true;

    profiles.default = {
      userSettings = pkgs.lib.importJSON ./settings.json;
      keybindings = pkgs.lib.importJSON ./keybindings.json;

      # The extensions commented didn't work
      extensions = with pkgs; [
        vscode-extensions.aaron-bond.better-comments
        vscode-extensions.adpyke.codesnap
        vscode-extensions.alefragnani.project-manager
#        vscode-extensions.bierner.color-info
        vscode-extensions.biomejs.biome
        vscode-extensions.bradlc.vscode-tailwindcss
        vscode-extensions.catppuccin.catppuccin-vsc
        vscode-extensions.catppuccin.catppuccin-vsc-icons
        vscode-extensions.christian-kohler.npm-intellisense
        vscode-extensions.eamodio.gitlens
        vscode-extensions.enkia.tokyo-night
#        vscode-extensions.formulahendry.auto-close-tag
#        vscode-extensions.formulahendry.auto-rename-tag
        vscode-extensions.foxundermoon.shell-format
        vscode-extensions.github.github-vscode-theme
        vscode-extensions.jock.svg
        vscode-extensions.meganrogge.template-string-converter
        vscode-extensions.mvllow.rose-pine
        vscode-extensions.redhat.vscode-yaml
        vscode-extensions.streetsidesoftware.code-spell-checker
        vscode-extensions.teabyii.ayu
        vscode-extensions.unifiedjs.vscode-mdx
        vscode-extensions.usernamehw.errorlens
        vscode-extensions.yoavbls.pretty-ts-errors
        vscode-extensions.yzhang.markdown-all-in-one
        vscode-extensions.catppuccin.catppuccin-vsc-icons
        vscode-extensions.catppuccin.catppuccin-vsc
         vscode-extensions.bbenoist.nix
         vscode-extensions.bierner.github-markdown-preview
         vscode-extensions.yzhang.markdown-all-in-one
         vscode-extensions.ms-azuretools.vscode-docker

        # vscode-extensions.redhat.vscode-yaml
        # vscode-extensions.chakrounanas.turbo-console-log
        # vscode-extensions.meganrogge.template-string-converter
        # vscode-extensions.bradlc.vscode-tailwindcss
        # vscode-extensions.foxundermoon.shell-format
        # vscode-extensions.alefragnani.project-manager
        # vscode-extensions.wallabyjs.console-ninjarors
        # vscode-extensions.streetsidesoftware.code-spell-checker-portuguese
        # vscode-extensions.github.github-vscode-theme
        # vscode-extensions.miguelsolorio.fluent-icons
        # vscode-extensions.streetsidesoftware.code-spell-checker
        # vscode-extensions.maximus136.change-string-case
        # vscode-extensions.catppuccin.catppuccin-vsc-icons
        # vscode-extensions.catppuccin.catppuccin-vsc
        # vscode-extensions.biomejs.biome
        # vscode-extensions.formulahendry.auto-rename-tag
        # vscode-extensions.formulahendry.auto-close-tag
        # vscode-extensions.aliariff.auto-add-brackets
        # vscode-extensions.pflannery.vscode-versionlens
      ];
    };
  };
}

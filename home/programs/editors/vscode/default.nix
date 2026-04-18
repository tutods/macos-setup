{
  config,
  lib,
  pkgs,
  ...
}: {
  programs.vscode = {
    enable = true;

    profiles.default = {
      userSettings = pkgs.lib.importJSON ./settings.json;
      keybindings = pkgs.lib.importJSON ./keybindings.json;

      # Extensions available in nixpkgs — managed declaratively.
      # Extensions NOT in nixpkgs are installed via home.activation below.
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

  # Marketplace extensions not available in nixpkgs.
  # code CLI is available since home.activation runs as the logged-in user.
  home.activation.installVscodeExtensions = lib.hm.dag.entryAfter ["writeBoundary"] ''
    code=/etc/profiles/per-user/${config.home.username}/bin/code

    if [ ! -x "$code" ]; then
      echo "↣ VSCode not found — skipping marketplace extension install"
    else
      _code_install() {
        local ext="$1"
        if "$code" --list-extensions 2>/dev/null | grep -qi "^$ext$"; then
          echo "  ✓ $ext already installed"
        else
          echo "  ↣ Installing $ext"
          "$code" --install-extension "$ext" --force 2>/dev/null \
            && echo "  ✓ $ext" \
            || echo "  ✗ $ext failed"
        fi
      }

      echo "↣ VSCode marketplace extensions"
      _code_install "ahmadawais.shades-of-purple"
      _code_install "aliariff.auto-add-brackets"
      _code_install "anaer.vscode-version-lens"
      _code_install "streetsidesoftware.code-spell-checker-portuguese"
      _code_install "chakrounanas.turbo-console-log"
      _code_install "miguelsolorio.fluent-icons"
      _code_install "pflannery.vscode-versionlens"
      _code_install "piotrpalarz.vscode-gitignore-generator"
      _code_install "csstools.postcss"
      _code_install "daltonmenezes.aura-theme"
      _code_install "formulahendry.auto-complete-tag"
      _code_install "maximus136.change-string-case"
      _code_install "miguelsolorio.symbols"
      _code_install "swiftlydaniel.oklch-color-visualiser"
      _code_install "wallabyjs.console-ninja"
      _code_install "yutengjing.vscode-classic-experience"
      _code_install "zignd.html-css-class-completion"
    fi
  '';
}

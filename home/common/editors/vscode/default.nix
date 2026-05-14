{
  pkgs,
  pkgsUnstable,
  ...
}: {
  programs.vscode = {
    enable = true;

    profiles.default = {
      userSettings = pkgs.lib.importJSON ./settings.json;
      keybindings = pkgs.lib.importJSON ./keybindings.json;

      # Fully declarative extension management:
      # - stable nixpkgs extensions
      # - extra extensions available only in nixpkgs-unstable
      # - remaining marketplace extensions pinned by version + hash
      extensions =
        (with pkgs.vscode-extensions; [
          aaron-bond.better-comments
          adpyke.codesnap
          alefragnani.project-manager
          bbenoist.nix
          bierner.color-info
          bierner.github-markdown-preview
          biomejs.biome
          bradlc.vscode-tailwindcss
          catppuccin.catppuccin-vsc
          catppuccin.catppuccin-vsc-icons
          christian-kohler.npm-intellisense
          eamodio.gitlens
          enkia.tokyo-night
          formulahendry.auto-close-tag
          formulahendry.auto-rename-tag
          foxundermoon.shell-format
          github.github-vscode-theme
          jock.svg
          meganrogge.template-string-converter
          ms-azuretools.vscode-docker
          mvllow.rose-pine
          redhat.vscode-yaml
          streetsidesoftware.code-spell-checker
          teabyii.ayu
          unifiedjs.vscode-mdx
          usernamehw.errorlens
          yoavbls.pretty-ts-errors
          yzhang.markdown-all-in-one
        ])
        ++ (with pkgsUnstable.vscode-extensions; [
          miguelsolorio.fluent-icons
        ])
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace [
          {
            name = "shades-of-purple";
            publisher = "ahmadawais";
            version = "7.3.6";
            sha256 = "sha256-22ZywGew1Qh4YPi51JWTNQLKuz/nzx/iprUK96DQfYU=";
          }
          {
            name = "auto-add-brackets";
            publisher = "aliariff";
            version = "0.12.2";
            sha256 = "sha256-DH1NfneJTMC7BmOP4IiUG8J7BQtwOj4/k5Qn62DkZ7Q=";
          }
          {
            name = "vscode-versionlens";
            publisher = "pflannery";
            version = "1.28.0";
            sha256 = "sha256-IZjTHE51hdrQpDndsz5bBCKre0zmWkCAJa/v8k4iLy0=";
          }
          {
            name = "code-spell-checker-portuguese";
            publisher = "streetsidesoftware";
            version = "2.0.4";
            sha256 = "sha256-ZC2sucAiWTz8IVPLlJVegLy7u2keUFZMAVKvVG3X3DY=";
          }
          {
            name = "turbo-console-log";
            publisher = "chakrounanas";
            version = "3.21.2";
            sha256 = "sha256-WiX5gf1TNHaCtFedwg4pv7rW/W4LfQxPVi0Fe4CmYqQ=";
          }
          {
            name = "vscode-gitignore-generator";
            publisher = "piotrpalarz";
            version = "1.0.4";
            sha256 = "sha256-lTpvivD1+FMyn05CswHAFgjfvPDJnFDaQXKg8/J0Pag=";
          }
          {
            name = "postcss";
            publisher = "csstools";
            version = "1.0.9";
            sha256 = "sha256-5pGDKme46uT1/35WkTGL3n8ecc7wUBkHVId9VpT7c2U=";
          }
          {
            name = "aura-theme";
            publisher = "daltonmenezes";
            version = "2.1.2";
            sha256 = "sha256-r6pPpvJ1AZsM0RYF+xHsZ4b4QTszN+wELr1SENsUDFA=";
          }
          {
            name = "auto-complete-tag";
            publisher = "formulahendry";
            version = "0.1.0";
            sha256 = "sha256-X7/LdajN98ySJs7XbnRzW/09TbJ23ZZo1J/yEzh9tZM=";
          }
          {
            name = "change-string-case";
            publisher = "maximus136";
            version = "1.1.2";
            sha256 = "sha256-6luPBsjy8FljwKhJKvtjBiik05KfOATG3ag/4sre654=";
          }
          {
            name = "symbols";
            publisher = "miguelsolorio";
            version = "0.0.25";
            sha256 = "sha256-nhymeLPfgGKyg3krHqRYs2iWNINF6IFBtTAp5HcwMs8=";
          }
          {
            name = "oklch-color-visualiser";
            publisher = "swiftlydaniel";
            version = "1.0.3";
            sha256 = "sha256-eSvG0gf3LNTB/HlZL/08f5LJhayp1HlpkA4Cs+uc2RU=";
          }
          {
            name = "console-ninja";
            publisher = "wallabyjs";
            version = "1.0.527";
            sha256 = "sha256-zQ/56HbcLxVKa2X37mnvdVEhVGYm9RQ01J0m34sA9sU=";
          }
          {
            name = "vscode-classic-experience";
            publisher = "yutengjing";
            version = "7.0.0";
            sha256 = "sha256-UNfsKasCJnoCiTPELu3bneRNLaFxpPScCXnDvKFoRRY=";
          }
          {
            name = "html-css-class-completion";
            publisher = "zignd";
            version = "1.20.0";
            sha256 = "sha256-3BEppTBc+gjZW5XrYLPpYUcx3OeHQDPW8z7zseJrgsE=";
          }
        ];
    };
  };
}

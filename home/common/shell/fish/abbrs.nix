# Git abbreviations come from the plugin-git fish plugin (see default.nix);
# only deliberate overrides of it belong here. Overrides work because plugins
# load from conf.d, which fish sources before config.fish where these abbrs
# are defined.
{
  # Common abbreviations
  cp = "cp -i";
  mv = "mv -i";
  mkdir = "mkdir -p";
  caf = "caffeinate -dim"; # prevent display, idle and disk sleep

  # Overrides plugin-git: upstream's unquoted pipe truncates gtv to `git tag`.
  gtv = "git tag | sort -V";

  # pnpm abbreviations
  pi = "pnpm install";
  pa = "pnpm add";
  pad = "pnpm add -D";
  prd = "pnpm run dev";
  pb = "pnpm run build";
  pts = "pnpm run test";

  # AI token tools
  ccusage = "npx ccusage@latest";

  # Homebrew abbreviations
  bi = "brew install";
  bci = "brew install --cask";
  bri = "brew reinstall";
  br = "brew remove";
  bup = "brew update";
  bug = "brew upgrade";
  bcl = "brew cleanup";
  bsearch = "brew search";
}

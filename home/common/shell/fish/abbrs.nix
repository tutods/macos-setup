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

  # code-review-graph, per-repo and opt-in: the MCP server answers nothing in a
  # repo with no graph. `build` only writes .code-review-graph/; the scattering
  # command is `install`, which registers hooks and generated skills across
  # every AI CLI it knows about, and is never run here.
  crgb = "code-review-graph build";
  crgu = "code-review-graph update";
  crgs = "code-review-graph status";

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

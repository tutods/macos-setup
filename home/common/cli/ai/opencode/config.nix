{
  pkgs,
  lib,
  ...
}: let
  base = {
    "\$schema" = "https://opencode.ai/config.json";
    plugin = ["@warp-dot-dev/opencode-warp"];
    experimental.openTelemetry = false;
    share = "disabled";
    autoupdate = false;
    snapshot = false;
    logLevel = "WARN";
    disabled_providers = ["openai" "azure" "vertex" "bedrock"];
    permission.bash = {
      "*" = "ask";
      # Read-only file ops
      "bat *" = "allow";
      "cat *" = "allow";
      "head *" = "allow";
      "tail *" = "allow";
      "wc *" = "allow";
      # List / search
      "ls *" = "allow";
      "eza *" = "allow";
      "fd *" = "allow";
      "rg *" = "allow";
      "grep *" = "allow";
      # Data tools
      "jq *" = "allow";
      "yq *" = "allow";
      # System info
      "which *" = "allow";
      "command *" = "allow";
      "type *" = "allow";
      "pwd*" = "allow";
      "echo *" = "allow";
      "date*" = "allow";
      "uname*" = "allow";
      "hostname*" = "allow";
      "whoami*" = "allow";
      # CLI tools
      "fzf*" = "allow";
      "delta*" = "allow";
      "ttok*" = "allow";
      # RTK (token proxy)
      "rtk gain*" = "allow";
      "rtk discover*" = "allow";
      "rtk history*" = "allow";
      # Version checks
      "node --version*" = "allow";
      "npm --version*" = "allow";
      "pnpm --version*" = "allow";
      "python --version*" = "allow";
      "python3 --version*" = "allow";
      "nix --version*" = "allow";
      # Safe npx
      "npx skills ls*" = "allow";
      "npx ccusage*" = "allow";
      # Package manager queries (read-only)
      "npm install*" = "allow";
      "npm i" = "allow";
      "npm i *" = "allow";
      "npm ls*" = "allow";
      "npm list*" = "allow";
      "npm view*" = "allow";
      "npm info*" = "allow";
      "yarn install*" = "allow";
      "yarn" = "allow";
      "yarn *" = "allow";
      "pnpm ls*" = "allow";
      "pnpm list*" = "allow";
      "pnpm why*" = "allow";
      "pnpm install*" = "allow";
      "pnpm i" = "allow";
      "pnpm i *" = "allow";
      # Nix safe
      "nix show-config*" = "allow";
      "nix-collect-garbage*" = "allow";
      # Git — bare
      "git" = "allow";
      # Git — read-only
      "git status*" = "allow";
      "git diff*" = "allow";
      "git log*" = "allow";
      "git show*" = "allow";
      "git grep*" = "allow";
      "git blame*" = "allow";
      "git fetch*" = "allow";
      "git branch" = "allow";
      "git branch -l*" = "allow";
      "git branch --list*" = "allow";
      "git remote" = "allow";
      "git remote -v*" = "allow";
      "git remote show*" = "allow";
      "git stash list*" = "allow";
      "git stash show*" = "allow";
      "git config --list*" = "allow";
      "git config --get*" = "allow";
      "git config" = "allow";
      "git rev-parse*" = "allow";
      "git rev-list*" = "allow";
      "git ls-files*" = "allow";
      "git ls-tree*" = "allow";
      "git shortlog*" = "allow";
      "git describe*" = "allow";
      "git for-each-ref*" = "allow";
      "git merge-base*" = "allow";
      "git worktree list*" = "allow";
      "git whatchanged*" = "allow";
      "git reflog" = "allow";
      "git cat-file*" = "allow";
      "git tag -l*" = "allow";
      "git tag --list*" = "allow";
      "git tag" = "allow";
    };
  };
in {
  # opencode: ~/.config/opencode/opencode.json  (base config)
  # Nix wins for static fields; mcp/provider preserved by later activations.
  home.activation.opencodeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.config/opencode/opencode.json"
    base='${builtins.toJSON base}'

    mkdir -p "$HOME/.config/opencode"

    if [ -f "$target" ]; then
      existing_mcp=$(${pkgs.jq}/bin/jq -c '.mcp // {}' "$target")
      existing_provider=$(${pkgs.jq}/bin/jq -c '.provider // {}' "$target")
      echo "$base" \
        | ${pkgs.jq}/bin/jq \
            --argjson mcp      "$existing_mcp" \
            --argjson provider "$existing_provider" \
            'del(.env) + {mcp: $mcp, provider: $provider}' \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "$base" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';
}

# ── MCP Servers ───────────────────────────────────────────────────────────────
#
# Manages MCP server config for Claude Code CLI and opencode.
#
# On re-deploy: Nix merges new servers into existing config.
# Servers added manually (claude mcp add / opencode UI) are preserved.
#
# ── GitHub Token ──────────────────────────────────────────────────────────────
# The GitHub MCP server reads GITHUB_PERSONAL_ACCESS_TOKEN from env.
# The wrapper below maps GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN at spawn.
#
# 1. Create token: https://github.com/settings/tokens/new
#    Scopes: repo, read:org, read:user
#    Preferred: fine-grained token scoped to your orgs
#
# 2. Store in secrets (never commit):
#    echo 'set -gx GITHUB_TOKEN "ghp_xxx"' >> ~/.config/fish/secrets.fish
#    # or via doppler (personal machine):
#    doppler secrets set GITHUB_TOKEN ghp_xxx
#
# ── Context7 API Key ──────────────────────────────────────────────────────────
# context7 is a remote MCP (HTTP) — its API key can't be injected via env
# at spawn time like github. The key must be a literal value in opencode.json.
#
# opencode.json is NOT in the dotfiles git repo (live file at ~/.config/opencode/).
# The key should still NOT sit in plaintext there long-term.
#
# Recommended: store it in secrets.fish, then inject it once via:
#   opencode-context7-setup   ← fish function deployed by this module
#
# That function reads CONTEXT7_API_KEY from your shell env and writes it into
# opencode.json. Re-run after rotating the key.
#
# 1. Get/rotate key: https://context7.com/settings
# 2. Store: echo 'set -gx CONTEXT7_API_KEY "ctx7sk-xxx"' >> ~/.config/fish/secrets.fish
# 3. Inject: opencode-context7-setup
#
{
  config,
  pkgs,
  lib,
  ...
}: let
  home = config.home.homeDirectory;

  # Maps GITHUB_TOKEN → GITHUB_PERSONAL_ACCESS_TOKEN at runtime.
  # ${ } is shell expansion at server spawn, not Nix build time.
  githubServer = {
    command = "sh";
    args = ["-c" "GITHUB_PERSONAL_ACCESS_TOKEN=\"\${GITHUB_TOKEN:-}\" npx -y @modelcontextprotocol/server-github"];
  };

  filesystemServer = {
    command = "npx";
    args = ["-y" "@modelcontextprotocol/server-filesystem" home];
  };

  # ── Claude Code CLI ──────────────────────────────────────────────────────────
  # File: ~/.claude/claude_desktop_config.json
  # Claude Code reads this on startup; does NOT write to it unless `claude mcp add`.
  claudeMcpServers = {
    filesystem = filesystemServer;
    github = githubServer;
  };

  # ── opencode ─────────────────────────────────────────────────────────────────
  # File: ~/.config/opencode/opencode.json  (mcp key, type = "local" for stdio)
  # Merged into existing config — preserves plugin, experimental, share, context7.
  opencodeMcpServers = {
    filesystem = filesystemServer // {type = "local"; enabled = true;};
    github = githubServer // {type = "local"; enabled = true;};
  };

  opencodeBaseConfig = {
    "\$schema" = "https://opencode.ai/config.json";
    plugin = ["@warp-dot-dev/opencode-warp"];
    experimental.openTelemetry = false;
    share = "disabled";
  };
in {
  # Claude Code: ~/.claude/claude_desktop_config.json
  home.activation.claudeMcp = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.claude/claude_desktop_config.json"
    nix_servers='${builtins.toJSON claudeMcpServers}'

    mkdir -p "$HOME/.claude"

    if [ -f "$target" ]; then
      existing_servers=$(${pkgs.jq}/bin/jq -c '.mcpServers // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson nix "$nix_servers" \
        --argjson live "$existing_servers" \
        '$nix + $live')
      ${pkgs.jq}/bin/jq --argjson servers "$merged" \
        '. + {mcpServers: $servers}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "{\"mcpServers\": $nix_servers}" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';

  # opencode: ~/.config/opencode/opencode.json  (base config: schema, plugin, experimental, share)
  # Runs before opencodeMcp so MCP servers merge on top of the base.
  home.activation.opencodeConfig = lib.hm.dag.entryAfter ["writeBoundary"] ''
    target="$HOME/.config/opencode/opencode.json"
    base='${builtins.toJSON opencodeBaseConfig}'

    mkdir -p "$HOME/.config/opencode"

    if [ -f "$target" ]; then
      # Nix wins for static fields; preserve mcp (managed by opencodeMcp activation)
      existing_mcp=$(${pkgs.jq}/bin/jq -c '.mcp // {}' "$target")
      echo "$base" \
        | ${pkgs.jq}/bin/jq --argjson mcp "$existing_mcp" '. + {mcp: $mcp}' \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "$base" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';

  # opencode: ~/.config/opencode/opencode.json  (mcp key)
  home.activation.opencodeMcp = lib.hm.dag.entryAfter ["writeBoundary" "opencodeConfig"] ''
    target="$HOME/.config/opencode/opencode.json"
    nix_servers='${builtins.toJSON opencodeMcpServers}'

    if [ -f "$target" ]; then
      existing_mcp=$(${pkgs.jq}/bin/jq -c '.mcp // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson nix "$nix_servers" \
        --argjson live "$existing_mcp" \
        '$nix + $live')
      ${pkgs.jq}/bin/jq --argjson mcp "$merged" \
        '. + {mcp: $mcp}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "{\"mcp\": $nix_servers}" | ${pkgs.jq}/bin/jq '.' > "$target"
    fi
  '';

  # Fish helper: inject CONTEXT7_API_KEY from env into opencode.json.
  # Usage: set CONTEXT7_API_KEY in secrets.fish, then run `opencode-context7-setup`.
  programs.fish.functions.opencode-context7-setup = {
    description = "Inject CONTEXT7_API_KEY from env into opencode.json";
    body = ''
      set -l target "$HOME/.config/opencode/opencode.json"
      set -l key $CONTEXT7_API_KEY

      if test -z "$key"
        echo "Error: CONTEXT7_API_KEY not set"
        echo "Add to ~/.config/fish/secrets.fish: set -gx CONTEXT7_API_KEY ctx7sk-xxx"
        return 1
      end

      if not test -f "$target"
        echo "Error: $target not found — run darwin-rebuild first"
        return 1
      end

      set -l entry (printf '{"type":"remote","url":"https://mcp.context7.com/mcp","enabled":true,"headers":{"CONTEXT7_API_KEY":"%s"}}' "$key")
      ${pkgs.jq}/bin/jq --argjson ctx $entry \
        '.mcp.context7 = $ctx' "$target" \
        > "$target.tmp"; and mv "$target.tmp" "$target"

      echo "context7 MCP key updated in $target"
    '';
  };
}

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
    args = ["-y" "@modelcontextprotocol/server-filesystem" "${home}/.dotfiles" "${home}/Developer"];
  };

  playwrightServer = {
    command = "npx";
    args = ["-y" "@playwright/mcp" "--isolated" "--headless"];
  };

  # ── Claude Code CLI ──────────────────────────────────────────────────────────
  # File: ~/.claude/claude_desktop_config.json
  # Claude Code reads this on startup; does NOT write to it unless `claude mcp add`.
  claudeMcpServers = {
    filesystem = filesystemServer;
    github = githubServer;
    playwright = playwrightServer;
  };

  # ── opencode ─────────────────────────────────────────────────────────────────
  # File: ~/.config/opencode/opencode.json  (mcp key, type = "local" for stdio)
  # Merged into existing config — preserves plugin, experimental, share.
  opencodeMcpServers = {
    filesystem =
      filesystemServer
      // {
        type = "local";
        enabled = true;
      };
    github =
      githubServer
      // {
        type = "local";
        enabled = true;
      };
    playwright =
      playwrightServer
      // {
        type = "local";
        enabled = true;
      };
  };

  opencodeBaseConfig = {
    "\$schema" = "https://opencode.ai/config.json";
    plugin = ["@warp-dot-dev/opencode-warp"];
    experimental.openTelemetry = false;
    share = "disabled";
    autoupdate = "manual";
    snapshot = false;
    logLevel = "WARN";
    disabled_providers = ["openai" "azure" "vertex" "bedrock"];
    permission.bash = {
      "git *" = "allow";
      "*" = "ask";
    };
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

  # Role-specific MCP servers (e.g. personal: docker, postgres, shadcn)
  home.activation.claudeMcpExtra = lib.hm.dag.entryAfter ["writeBoundary" "claudeMcp"] ''
    target="$HOME/.claude/claude_desktop_config.json"
    extra_servers='${builtins.toJSON config.home.ai.extraMcpServers}'

    if [ "$extra_servers" != "{}" ] && [ -f "$target" ]; then
      existing=$(${pkgs.jq}/bin/jq -c '.mcpServers // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson extra "$extra_servers" \
        --argjson live "$existing" \
        '$extra + $live')
      ${pkgs.jq}/bin/jq --argjson servers "$merged" \
        '. + {mcpServers: $servers}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';

  home.activation.opencodeMcpExtra = lib.hm.dag.entryAfter ["writeBoundary" "opencodeMcp"] ''
    target="$HOME/.config/opencode/opencode.json"
    extra_servers='${builtins.toJSON (
      lib.mapAttrs (_: v:
        v
        // {
          type = "local";
          enabled = true;
        })
      config.home.ai.extraMcpServers
    )}'

    if [ "$extra_servers" != "{}" ] && [ -f "$target" ]; then
      existing=$(${pkgs.jq}/bin/jq -c '.mcp // {}' "$target")
      merged=$(${pkgs.jq}/bin/jq -cn \
        --argjson extra "$extra_servers" \
        --argjson live "$existing" \
        '$extra + $live')
      ${pkgs.jq}/bin/jq --argjson mcp "$merged" \
        '. + {mcp: $mcp}' "$target" \
        > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';
}

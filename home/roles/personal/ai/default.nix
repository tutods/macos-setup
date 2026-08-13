{
  aiLib,
  pkgs,
  lib,
  ...
}: {
  # Personal-only custom skills — real dirs in ~/.claude/skills.
  # (Custom skills shared across roles live in home/common/ai/skills/default.nix.)
  imports = [
    (aiLib.mkLocalSkills {
      inherit lib;
      label = "personal";
      dir = ./skills/local;
      names = ["obsidian-vault" "optimize-images" "personal-stack" "github-project-hygiene"];
    })
    (aiLib.mkLocalAgents {
      inherit lib;
      label = "personal";
      dir = ./agents/local;
      names = ["github-project-hygiene"];
    })
  ];

  # Temporary — Kimi Code CLI, remove when done trying it out.
  home.packages = [
    (pkgs.writeShellScriptBin "kimi" ''
      exec ${pkgs.nodejs}/bin/npx -y @moonshot-ai/kimi-code@latest "$@"
    '')
  ];

  # Stack reference is the `personal-stack` skill above, not an always-on
  # instruction — it is irrelevant during Nix or content work.
  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  # No personal-only plugins. Machine-wide plugins are generic only (see
  # home/common/ai/plugins.nix) — domain packs (SEO, social media, marketing,
  # design tooling) are enabled per project in that repo's .claude/settings.json.

  # postgres dropped — @modelcontextprotocol/server-postgres was archived
  # upstream, and it only ever did read-only queries + schema inspection.
  # `doppler run -- psql` covers that without a stale server in the loop.
  home.ai.extraMcpServers = {
    shadcn = aiLib.mkServer {
      cmd = "npx";
      args = ["-y" "shadcn@latest" "mcp"];
    };
  };
}

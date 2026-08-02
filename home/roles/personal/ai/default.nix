{
  pkgs,
  lib,
  ...
}: let
  ai = import ../../../../lib/ai.nix {inherit pkgs;};
in {
  # Temporary — Kimi Code CLI, remove when done trying it out.
  home.packages = [
    (pkgs.writeShellScriptBin "kimi" ''
      exec ${pkgs.nodejs}/bin/npx -y @moonshot-ai/kimi-code@latest "$@"
    '')
  ];

  home.ai.extraInstructions =
    ai.appendIfNonEmpty
    (builtins.readFile ./instructions.md)
    (builtins.readFile ../../../common/cli/ai/context/stack-personal.md);

  home.ai.extraSkillsManifest = builtins.readFile ./skills/manifest.txt;

  # Personal-only local skills — deployed to both agents, this role only.
  # (Common local skills, shared across roles, live in ~/.dotfiles/skills/default.nix instead.)
  home.file = lib.listToAttrs (lib.concatMap (name: [
    {
      name = ".agents/skills/${name}";
      value = {
        source = ./skills/local/${name};
        force = true;
      };
    }
    {
      name = ".claude/skills/${name}";
      value = {
        source = ./skills/local/${name};
        force = true;
      };
    }
  ]) ["elementor-crocoblock" "optimize-images"]);

  home.ai.extraMcpServers = {
    docker = ai.mkServer {
      cmd = "docker";
      args = ["mcp" "gateway" "run"];
    };
    postgres = ai.mkServer {
      cmd = "sh";
      args = ["-c" "doppler run -- npx -y @modelcontextprotocol/server-postgres"];
    };
    shadcn = ai.mkServer {
      cmd = "npx";
      args = ["-y" "shadcn@latest" "mcp"];
    };
  };
}

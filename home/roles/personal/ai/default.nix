{
  pkgs,
  lib,
  ...
}: let
  ai = import ../../../../lib/ai.nix {inherit pkgs;};
in {
  home.ai.extraInstructions =
    ai.appendIfNonEmpty
    (builtins.readFile ./instructions.md)
    (builtins.readFile ../../../common/cli/ai/context/stack-personal.md);

  home.ai.extraSkillsManifest = builtins.readFile ./skills/manifest.txt;

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

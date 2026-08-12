{lib, ...}: {
  options.home.ai = {
    extraInstructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra AI instructions appended to shared instructions (role-specific)";
    };

    extraMcpServers = lib.mkOption {
      default = {};
      description = "Role-specific MCP servers merged into claude_desktop_config.json";
      type = lib.types.attrsOf (lib.types.submodule {
        options = {
          command = lib.mkOption {
            type = lib.types.str;
            description = "Command to launch the MCP server";
          };
          args = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [];
            description = "Arguments passed to command";
          };
          env = lib.mkOption {
            type = lib.types.attrsOf lib.types.str;
            default = {};
            description = "Environment variables injected at server spawn";
          };
        };
      });
    };

    marketplaces = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = {};
      example = {caveman = "JuliusBrussee/caveman";};
      description = ''
        Claude Code plugin marketplaces, as `<key> = "<owner>/<repo>"`.

        The key is the marketplace identifier used in `home.ai.plugins`
        (`<plugin>@<key>`) — it is chosen here, not read from the repo's
        marketplace.json. Keep it stable: renaming a key orphans every plugin
        already installed under the old name.

        `claude-plugins-official` is built into Claude Code — do not list it.
      '';
    };

    customSkills = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      internal = true;
      description = ''
        Names of in-repo skills copied into ~/.claude/skills. Populated by
        `lib/ai.nix:mkLocalSkills`, not set by hand — skills/default.nix reads
        it to report directories in ~/.claude/skills that this repo doesn't own.
      '';
    };

    customAgents = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      internal = true;
      description = ''
        Names of in-repo subagents installed to ~/.claude/agents. Populated by
        `lib/ai.nix:mkLocalAgents`, not set by hand.
      '';
    };

    plugins = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      example = ["caveman@caveman"];
      description = ''
        Plugins to enable, as `<plugin>@<marketplace>`. Every non-custom skill
        arrives this way; custom in-repo skills are deployed by skills/default.nix.
      '';
    };
  };
}

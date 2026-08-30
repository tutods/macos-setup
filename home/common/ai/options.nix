{lib, ...}: {
  options.home.ai = {
    extraInstructions = lib.mkOption {
      type = lib.types.lines;
      default = "";
      description = "Extra AI instructions appended to shared instructions (role-specific)";
    };

    vaultFolders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["Conventions" "Lessons" "Decisions" "Process" "Projects" "Clients" "Notes"];
      description = ''
        Vault folders the SessionStart hook indexes into context. Scope this
        per role: the work machine must not have personal-context folders
        (freelance clients, personal projects) injected into every session.
        The vault stays readable either way, this only scopes the injection.
      '';
    };

    extraMcpServers = lib.mkOption {
      default = {};
      description = "Role-specific MCP servers merged into ~/.claude.json's mcpServers";
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
      example = {caveman = "JuliusBrussee/caveman@df2ccd85c94ec3c8289cb62ac020d241ccfb0c60";};
      description = ''
        Claude Code plugin marketplaces, as `<key> = "<owner>/<repo>[@<commit sha>]"`.
        The key is chosen here (not read from the repo) and used in
        `home.ai.plugins` as `<plugin>@<key>`; renaming it orphans
        already-installed plugins. The optional `@<sha>` pins the marketplace to
        a reviewed commit instead of HEAD; third-party marketplaces must be
        pinned (their skills execute locally, this is the supply chain).
        `claude-plugins-official` is built in, do not list it.
      '';
    };

    customSkills = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      internal = true;
      description = ''
        Names of in-repo skills copied into ~/.claude/skills. Populated by
        `lib/ai.nix:mkLocalSkills`; skills/default.nix reads it to report
        directories in ~/.claude/skills that this repo doesn't own.
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

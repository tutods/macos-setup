# Shared helpers for the AI wiring tree under home/common/ai.
#
# Why this exists: the per-tool trees each grew their own copy of the same
# patterns — a tiny `mkMcp`-style helper, a jq-based "merge key into JSON file"
# activation script, and an append-if-non-empty concatenator. Concentrating
# those here means a new tool is one call site, not new copies.
#
# Do not import this by relative path. It is passed to every Home Manager
# module as the `aiLib` argument, wired once in lib/mkHost.nix via
# home-manager.extraSpecialArgs:
#
#   { aiLib, lib, ... }: { imports = [ (aiLib.mkLocalSkills { ... }) ]; }
{pkgs}: let
  jqBin = "${pkgs.jq}/bin/jq";
in {
  # Build an MCP server record. Replaces the duplicated `mkMcp` helpers that
  # lived in roles/personal/ai/default.nix and roles/work/ai/default.nix.
  mkServer = {
    cmd,
    args,
    env ? {},
  }: {
    command = cmd;
    inherit args env;
  };

  # Append `extra` to `base` only when `extra` is non-empty.
  # Replaces the appendIfNonEmpty in instructions/default.nix (the list branch
  # was dead — extraInstructions is always `lines`).
  appendIfNonEmpty = base: extra:
    if extra == ""
    then base
    else base + "\n\n" + extra;

  # Install in-repo ("custom") skills straight into ~/.claude/skills as real,
  # writable directories.
  #
  # Deliberately not `home.file`: that produces a symlink into the read-only
  # Nix store, and Claude Code writes inside a skill directory. A plain copy
  # keeps the tree writable, and everything lives under ~/.claude — no
  # ~/.agents indirection.
  #
  # Runs after `linkGeneration` so Home Manager has already torn down the
  # previous generation's symlinks; copying earlier would have them removed.
  #
  # Returns a module — use it in `imports`:
  #   imports = [ (ai.mkLocalSkills { inherit lib; label = "work"; ... }) ];
  #
  # Also records the names in `home.ai.customSkills`, which skills/default.nix
  # uses to spot leftovers in ~/.claude/skills that this repo doesn't manage.
  #
  #   lib   — the module-args `lib` (needs `lib.hm.dag`)
  #   label — activation-name suffix and log label; unique per call site
  #   dir   — directory holding the skill sources
  #   names — skill directory names inside `dir`
  mkLocalSkills = {
    lib,
    label,
    dir,
    names,
  }: {
    home.ai.customSkills = names;

    home.activation."localSkills-${label}" = lib.hm.dag.entryAfter ["writeBoundary" "linkGeneration"] ''
      dest="$HOME/.claude/skills"
      mkdir -p "$dest"
      ${lib.concatMapStringsSep "\n" (name: ''
          rm -rf "$dest/${name}"
          cp -R "${dir}/${name}" "$dest/${name}"
          chmod -R u+w "$dest/${name}"
        '')
        names}
      echo "↣ Custom skills (${label}): ${toString (builtins.length names)} installed"
    '';
  };

  # Install in-repo subagent definitions into ~/.claude/agents/<name>.md.
  #
  # Unlike mkLocalSkills this uses home.file: an agent file is read-only input —
  # Claude Code never writes inside one — so a store symlink is safe, and Home
  # Manager then removes the file for free when a name leaves the list.
  #
  # Also records the names in `home.ai.customAgents`, mirroring customSkills.
  #
  #   lib   — the module-args `lib`
  #   label — log label; unique per call site
  #   dir   — directory holding <name>.md files
  #   names — agent names (file basenames, and the frontmatter `name`)
  mkLocalAgents = {
    lib,
    label,
    dir,
    names,
  }: {
    home.ai.customAgents = names;

    home.file = lib.listToAttrs (map
      (name: lib.nameValuePair ".claude/agents/${name}.md" {source = "${dir}/${name}.md";})
      names);
  };

  # Generate a bash snippet that merges a single key into a JSON config file
  # via jq, creating the file with `{"<key>": <value>}` if it does not exist.
  #
  # Used by home/common/ai/mcp.nix (key="mcpServers").
  mergeJsonKey = {
    file,
    key,
    value,
    extraMerge ? null,
  }: let
    mergeClause =
      if extraMerge == null
      then ''. + {${key}: $v}''
      else extraMerge;
  in ''
    target="${file}"
    nix_value='${builtins.toJSON value}'
    mkdir -p "$(dirname "$target")"
    if [ -f "$target" ]; then
      ${jqBin} --argjson v "$nix_value" '${mergeClause}' "$target" > "$target.tmp" && mv "$target.tmp" "$target"
    else
      echo "{\"${key}\": $nix_value}" | ${jqBin} '.' > "$target"
    fi
  '';
}

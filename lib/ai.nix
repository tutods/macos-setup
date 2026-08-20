# Shared helpers for the AI wiring tree under home/common/ai.
#
# Passed to every Home Manager module as the `aiLib` argument (wired once in
# lib/mkHost.nix via home-manager.extraSpecialArgs), never import by path.
#
# Skills are copied into ~/.claude/skills because Claude Code writes inside a
# skill directory; agents and workflows are read-only input, so they get
# home.file store symlinks and Home Manager removes them when a name is dropped.
{pkgs}: let
  jqBin = "${pkgs.jq}/bin/jq";
in {
  mkServer = {
    cmd,
    args,
    env ? {},
  }: {
    command = cmd;
    inherit args env;
  };

  appendIfNonEmpty = base: extra:
    if extra == ""
    then base
    else base + "\n\n" + extra;

  mkLocalSkills = {
    lib,
    label,
    dir,
    names,
  }: {
    home.ai.customSkills = names;

    # After linkGeneration: Home Manager has torn down the previous
    # generation's symlinks by then, and copying earlier would have them removed.
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

  mkLocalAgents = {
    lib,
    dir,
    names,
  }: {
    home.file = lib.listToAttrs (map
      (name: lib.nameValuePair ".claude/agents/${name}.md" {source = "${dir}/${name}.md";})
      names);
  };

  mkLocalWorkflows = {
    lib,
    dir,
    names,
  }: {
    home.file = lib.listToAttrs (map
      (name: lib.nameValuePair ".claude/workflows/${name}.js" {source = "${dir}/${name}.js";})
      names);
  };

  # Merge a single key into a JSON config file, creating the file if absent.
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

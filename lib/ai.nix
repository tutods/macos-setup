# Shared helpers for the AI wiring tree under home/common/ai.
#
# Passed to every Home Manager module as the `aiLib` argument (wired once in
# lib/mkHost.nix via home-manager.extraSpecialArgs), never import by path.
#
# Skills are copied into ~/.claude/skills, not symlinked, because Claude Code has
# historically treated a skill dir as writable and a 0444 store symlink broke
# that. Nothing writes there now, but the copy is kept: it is cheap and the
# reconcile logic depends on real dirs. mkLocalSkills copies the declared set and
# customSkillsReconcile deletes any non-symlink dir it does not own.
# mkFetchedSkills does the same copy, but its source is a pinned fetchFromGitHub
# tree instead of a directory committed in this repo. Agents and workflows are
# plain read-only input and get home.file store symlinks.
{pkgs}: let
  jqBin = "${pkgs.jq}/bin/jq";
in rec {
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

  # Shared by mkLocalSkills and mkFetchedSkills: both copy a named set of
  # skill directories from some `src` into ~/.claude/skills at activation
  # time, differing only in where `src` comes from and whether the reverse
  # "every dir on disk must be declared" assertion applies (mkLocalSkills
  # owns its whole `local/` dir and can assert that; mkFetchedSkills only
  # owns a curated subset of someone else's repo, so it can't).
  mkSkillCopy = {
    lib,
    label,
    prefix,
    src,
    names,
  }: {
    home.ai.customSkills = names;

    assertions =
      map (name: {
        assertion = builtins.pathExists (src + "/${name}/SKILL.md");
        message = "${prefix} (${label}): '${name}' is in names but ${toString src}/${name}/SKILL.md is missing";
      })
      names;

    # After linkGeneration: Home Manager has torn down the previous generation's
    # symlinks by then, and copying earlier would have them removed. Before
    # customSkillsReconcile: that step deletes anything in ~/.claude/skills this
    # repo does not own, so every copy must land first.
    home.activation."${prefix}-${label}" = lib.hm.dag.entryBetween ["customSkillsReconcile"] ["writeBoundary" "linkGeneration"] ''
      dest="$HOME/.claude/skills"
      mkdir -p "$dest"
      ${lib.concatMapStringsSep "\n" (name: ''
          rm -rf "$dest/${name}"
          cp -R "${src}/${name}" "$dest/${name}"
          # Source is a 0444 store path; without this the next deploy's rm -rf
          # cannot recurse in to replace the copy.
          chmod -R u+w "$dest/${name}"
        '')
        names}
      echo "↣ Custom skills (${label}): ${toString (builtins.length names)} installed"
    '';
  };

  mkLocalSkills = {
    lib,
    label,
    dir,
    names,
  }: let
    copy = mkSkillCopy {
      inherit lib label names;
      prefix = "localSkills";
      src = dir;
    };
  in
    copy
    // {
      assertions =
        copy.assertions
        ++ (lib.mapAttrsToList (entry: kind: {
            assertion = kind != "directory" || builtins.elem entry names;
            message = "mkLocalSkills (${label}): ${toString dir}/${entry} exists but is not in the names list";
          })
          (builtins.readDir dir));
    };

  # Skills fetched from an external repo at build time instead of committed
  # into this repo, e.g. stablyai/orca's `orchestration`/`orca-cli` skills:
  # the user wants them reproducibly installed by ./nix.sh on any machine
  # without their content living in this repo's git history. Pinned by
  # rev + hash exactly like a plugin marketplace — bump deliberately after
  # reviewing the diff, never track a moving ref. Unlike mkLocalSkills, this
  # never asserts the fetched tree matches `names` exactly: it's a curated
  # subset of someone else's repo, not a directory this repo owns.
  mkFetchedSkills = {
    lib,
    label,
    owner,
    repo,
    rev,
    hash,
    subdir ? "",
    names,
  }: let
    fetched = pkgs.fetchFromGitHub {inherit owner repo rev hash;};
    src =
      if subdir == ""
      then fetched
      else fetched + "/${subdir}";
  in
    mkSkillCopy {
      inherit lib label names src;
      prefix = "fetchedSkills";
    };

  mkLocalAgents = {
    lib,
    dir,
    names,
  }: {
    home.file = lib.listToAttrs (map
      (name: lib.nameValuePair ".claude/agents/${name}.md" {source = "${dir}/${name}.md";})
      names);

    assertions =
      (map (name: {
          assertion = builtins.pathExists (dir + "/${name}.md");
          message = "mkLocalAgents: '${name}' is in names but ${toString dir}/${name}.md is missing";
        })
        names)
      ++ (lib.mapAttrsToList (entry: kind: {
          assertion = kind != "regular" || !lib.hasSuffix ".md" entry || builtins.elem (lib.removeSuffix ".md" entry) names;
          message = "mkLocalAgents: ${toString dir}/${entry} exists but is not in the names list";
        })
        (builtins.readDir dir));
  };

  mkLocalWorkflows = {
    lib,
    dir,
    names,
  }: {
    home.file = lib.listToAttrs (map
      (name: lib.nameValuePair ".claude/workflows/${name}.js" {source = "${dir}/${name}.js";})
      names);

    assertions =
      (map (name: {
          assertion = builtins.pathExists (dir + "/${name}.js");
          message = "mkLocalWorkflows: '${name}' is in names but ${toString dir}/${name}.js is missing";
        })
        names)
      ++ (lib.mapAttrsToList (entry: kind: {
          assertion = kind != "regular" || !lib.hasSuffix ".js" entry || builtins.elem (lib.removeSuffix ".js" entry) names;
          message = "mkLocalWorkflows: ${toString dir}/${entry} exists but is not in the names list";
        })
        (builtins.readDir dir));
  };

  # Merge a single key into a JSON config file, creating the file if absent.
  # The Nix value is passed through a store file, never interpolated into the
  # shell, so an apostrophe or a quote in it cannot break the activation script.
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
    valueFile = pkgs.writeText "aiLib-merge-${key}.json" (builtins.toJSON value);
  in ''
    target="${file}"
    mkdir -p "$(dirname "$target")"
    if [ -f "$target" ]; then
      ${jqBin} --slurpfile vw ${valueFile} '($vw[0]) as $v | ${mergeClause}' "$target" > "$target.tmp" && mv "$target.tmp" "$target" || {
        echo "aiLib: jq merge of ${key} into $target failed" >&2
        rm -f "$target.tmp"
        exit 1
      }
    else
      ${jqBin} -n --slurpfile vw ${valueFile} '($vw[0]) as $v | {} | ${mergeClause}' > "$target"
    fi
  '';

  # Merge a whole JSON object into a config file the target app also writes.
  # Top-level keys the Nix value defines replace the live value; other top-level
  # keys the live file has are kept. `permissions` merges one key deeper, so a
  # `permissions` sub-key Nix does not declare survives while the ones it does
  # (including `allow`, once declared) are replaced. `hooks` merges one key
  # deeper too, but a live hook event is kept ONLY if its name is in
  # `keepHookEvents`; every other foreign event is dropped on deploy, so nothing
  # can leave a permanent hook Nix never sanctioned. A deploy still resets agent
  # config to a known state. The Nix value goes through a store file, never the
  # shell, and jq writes the output on every path so the result is mode 0644.
  mergeJsonObject = {
    file,
    value,
    keepHookEvents ? [],
  }: let
    valueFile = pkgs.writeText "aiLib-merge-object.json" (builtins.toJSON value);
    keep = builtins.toJSON keepHookEvents;
  in ''
    target="${file}"
    mkdir -p "$(dirname "$target")"
    if [ -f "$target" ] && ${jqBin} -e 'type == "object"' "$target" >/dev/null 2>&1; then
      ${jqBin} -s '
        .[0] as $live | .[1] as $nix
        | ($live.hooks       | if type == "object" then . else {} end) as $lh
        | ($nix.hooks        | if type == "object" then . else {} end) as $nh
        | ($live.permissions | if type == "object" then . else {} end) as $lp
        | ($nix.permissions  | if type == "object" then . else {} end) as $np
        | ($live + $nix)
        | .hooks = (($lh | with_entries(select(.key as $k | ${keep} | index($k)))) + $nh)
        | .permissions = ($lp + $np)
      ' "$target" ${valueFile} > "$target.tmp" && mv "$target.tmp" "$target" || {
        echo "aiLib: jq merge into $target failed" >&2
        rm -f "$target.tmp"
        exit 1
      }
    else
      [ -f "$target" ] && cp "$target" "$target.bak" && echo "aiLib: $target was not a JSON object, backed up to $target.bak and replaced with the Nix value" >&2
      ${jqBin} . ${valueFile} > "$target.tmp" && mv "$target.tmp" "$target"
    fi
  '';
}

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
  # Single source of truth for the secret-path deny lists both harnesses
  # render: Claude Code's Bash() prefix rules in home/common/ai/settings.nix
  # and opencode's anchored-glob rules in
  # home/roles/personal/opencode/config.nix. Each family carries the shape
  # metadata both renderings need, explicitly:
  #   - `relative`: the path prefix (a trailing slash marks a directory
  #     family, which the glob spelling turns into `<p>*` = "anything under").
  #   - `scope`: which literal spellings the prefix rules emit — "home"
  #     families are typed as `~/<p>` or `$HOME/<p>`, "project" families as
  #     `<p>` or `./<p>`.
  #   - `opencodeGlob`: the anchored-glob spelling for opencode (where `*`
  #     also matches `/`, so the leading `*` covers tilde, absolute and
  #     project-relative text alike). Spelled out per family, never computed:
  #     if a family cannot render meaningfully in one harness, that must be
  #     explicit here (opencodeGlob = null excludes it from opencode, loudly,
  #     in this data), never dropped silently by a renderer.
  secretPathFamilies = [
    {
      relative = ".ssh/";
      scope = "home";
      opencodeGlob = "*.ssh/*";
    }
    {
      relative = ".aws/";
      scope = "home";
      opencodeGlob = "*.aws/*";
    }
    {
      relative = ".config/fish/secrets.fish";
      scope = "home";
      opencodeGlob = "*.config/fish/secrets.fish*";
    }
    {
      relative = ".config/git/private";
      scope = "home";
      opencodeGlob = "*.config/git/private*";
    }
    {
      relative = ".config/gcloud/";
      scope = "home";
      opencodeGlob = "*.config/gcloud/*";
    }
    {
      relative = ".env";
      scope = "project";
      opencodeGlob = "*.env*";
    }
    {
      relative = "secrets/";
      scope = "project";
      opencodeGlob = "*secrets/*";
    }
  ];

  # Reader commands whose `<reader> <secret path>` invocation both harnesses
  # deny. Best-effort against the casual path (prefix/glob matching over
  # literal command text), see the comments at each rendering site.
  secretReaders = ["cat" "bat" "less" "head" "tail" "base64"];

  # rtk subcommands that read content: rtk-rewrite turns `cat ~/.ssh/id_ed25519`
  # into `rtk read ~/.ssh/id_ed25519` before any rule sees it, so the plain
  # reader rows alone stop nothing once rtk is on PATH. Two-word prefixes
  # ("rtk read", never bare "rtk"): a bare "rtk" rule would blanket-match
  # every rtk subcommand, not just the reader ones.
  rtkReaderSubcommands = ["read" "ls" "tree" "grep" "rg" "json" "env" "find" "smart" "wc" "diff" "log"];

  # Claude Code spellings for one family: every literal way the model types
  # that path. Bash() rules never expand `~` and support only prefix matches,
  # so each family needs each spelling as its own rule.
  secretPrefixSpellings = homeDirectory: family:
    if family.scope == "home"
    then ["~/${family.relative}" "${homeDirectory}/${family.relative}"]
    else [family.relative "./${family.relative}"];

  # opencode's glob list. The `!= null` filter here is the ONLY place a family
  # may be excluded from opencode, and only because its own entry says so.
  secretOpencodeGlobs =
    map (f: f.opencodeGlob)
    (builtins.filter (f: f.opencodeGlob != null) secretPathFamilies);

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
    # Every mutation goes through Home Manager's `run` so a dry-run
    # activation previews the commands instead of mutating ~/.claude/skills.
    home.activation."${prefix}-${label}" = lib.hm.dag.entryBetween ["customSkillsReconcile"] ["writeBoundary" "linkGeneration"] ''
      dest="$HOME/.claude/skills"
      run mkdir -p "$dest"
      ${lib.concatMapStringsSep "\n" (name: ''
          run rm -rf "$dest/${name}"
          run cp -R "${src}/${name}" "$dest/${name}"
          # Source is a 0444 store path; without this the next deploy's rm -rf
          # cannot recurse in to replace the copy.
          run chmod -R u+w "$dest/${name}"
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
  # jq writes to a mktemp file (reading is harmless) and only the final
  # `run install` touches the target, so a dry-run activation previews the
  # write instead of performing it and never litters next to the target.
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
    run mkdir -p "$(dirname "$target")"
    merged=$(mktemp)
    if [ -f "$target" ]; then
      if ! ${jqBin} --slurpfile vw ${valueFile} '($vw[0]) as $v | ${mergeClause}' "$target" > "$merged"; then
        echo "aiLib: jq merge of ${key} into $target failed" >&2
        rm -f "$merged"
        exit 1
      fi
    else
      ${jqBin} -n --slurpfile vw ${valueFile} '($vw[0]) as $v | {} | ${mergeClause}' > "$merged"
    fi
    run install -m 0644 "$merged" "$target"
    rm -f "$merged"
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
  # shell. jq writes into a mktemp file and only `run install -m 0644` (plus
  # the `run cp` backup) touches the target, so the result is mode 0644 on
  # every path and a dry-run activation previews the writes instead of
  # performing them.
  mergeJsonObject = {
    file,
    value,
    keepHookEvents ? [],
  }: let
    valueFile = pkgs.writeText "aiLib-merge-object.json" (builtins.toJSON value);
    keep = builtins.toJSON keepHookEvents;
  in ''
    target="${file}"
    run mkdir -p "$(dirname "$target")"
    merged=$(mktemp)
    if [ -f "$target" ] && ${jqBin} -e 'type == "object"' "$target" >/dev/null 2>&1; then
      if ! ${jqBin} -s '
        .[0] as $live | .[1] as $nix
        | ($live.hooks       | if type == "object" then . else {} end) as $lh
        | ($nix.hooks        | if type == "object" then . else {} end) as $nh
        | ($live.permissions | if type == "object" then . else {} end) as $lp
        | ($nix.permissions  | if type == "object" then . else {} end) as $np
        | ($live + $nix)
        | .hooks = (($lh | with_entries(select(.key as $k | ${keep} | index($k)))) + $nh)
        | .permissions = ($lp + $np)
      ' "$target" ${valueFile} > "$merged"; then
        echo "aiLib: jq merge into $target failed" >&2
        rm -f "$merged"
        exit 1
      fi
    else
      if [ -f "$target" ]; then
        # No backup, no wholesale replacement: the live file is the only copy
        # of whatever non-object content it holds.
        if run cp "$target" "$target.bak"; then
          echo "aiLib: $target was not a JSON object, backed up to $target.bak and replaced with the Nix value" >&2
        else
          echo "aiLib: could not back up $target to $target.bak; refusing to replace it" >&2
          rm -f "$merged"
          exit 1
        fi
      fi
      ${jqBin} . ${valueFile} > "$merged"
    fi
    run install -m 0644 "$merged" "$target"
    rm -f "$merged"
  '';
}

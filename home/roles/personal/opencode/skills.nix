# opencode-only skills installed via `npx skills add`, for sources with no
# .claude-plugin/marketplace.json (docs/dropped-skill-sources.md), so they
# can never become Claude plugins. Writes only under ~/.agents/skills;
# ~/.claude/skills is untouched.
{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (config.home.ai) opencodeSkillsSources;

  manifestHash = builtins.hashString "sha256" (lib.concatStringsSep "\n" opencodeSkillsSources);
  sourcesJson = pkgs.writeText "opencode-skill-sources.json" (builtins.toJSON opencodeSkillsSources);
  jqBin = "${pkgs.jq}/bin/jq";
in {
  options.home.ai.opencodeSkillsSources = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [
      "vercel-labs/agent-skills"
      "biomejs/biome"
      "mindrally/skills"
      "vercel/turborepo"
      "remotion-dev/skills"
    ];
    description = ''
      Skill sources installed into ~/.agents/skills via `npx skills add`,
      as `<owner>/<repo>`. Exposed as an option (not a `let`-bound local) so
      deploy-doctor.sh can `nix eval` the same list opencodeSkillsInstall
      and opencodeSkillsReconcile use, instead of scraping this file's text.
    '';
  };

  options.home.ai.opencodeSkillsPrune = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Actually delete directories under ~/.agents/skills that no declared
      source provides. Default false: this is a bulk delete of user data, so
      the reconcile step only prints the stale-directory list and the exact
      `rm -rf` command until this is flipped on deliberately.
    '';
  };

  config.home.activation.opencodeSkillsInstall = lib.hm.dag.entryAfter ["writeBoundary"] ''
    agentsDir="${config.home.homeDirectory}/.agents"
    skillsDir="$agentsDir/skills"
    stamp="$agentsDir/.skill-sources-hash"

    if ! command -v npx >/dev/null 2>&1; then
      echo "  ⚠ opencode skills: npx not found on PATH, skipping install"
    elif [ -f "$stamp" ] && [ "$(cat "$stamp" 2>/dev/null)" = "${manifestHash}" ]; then
      $VERBOSE_ECHO "opencode skills: sources unchanged, skipping install"
    else
      mkdir -p "$skillsDir"
      $VERBOSE_ECHO "opencode skills: installing ${toString (builtins.length opencodeSkillsSources)} source(s)"
      ${lib.concatMapStringsSep "\n" (src: ''
        run npx -y skills@latest add ${lib.escapeShellArg src} -g -a opencode -s '*' -y --copy \
          || echo "  ⚠ opencode skills: failed to install '${src}', continuing"
      '')
      opencodeSkillsSources}
      printf '%s' "${manifestHash}" > "$stamp"
    fi
  '';

  # Matches unowned dirs against .skill-lock.json's per-skill `source` field
  # (the tool's own install manifest), not the source list directly: one
  # source can produce several skill directories under different names.
  config.home.activation.opencodeSkillsReconcile = lib.hm.dag.entryAfter ["opencodeSkillsInstall"] ''
        skillsDir="${config.home.homeDirectory}/.agents/skills"
        lockFile="${config.home.homeDirectory}/.agents/.skill-lock.json"

        if [ -d "$skillsDir" ]; then
          owned=""
          if [ -f "$lockFile" ]; then
            owned=$(${jqBin} -r --slurpfile srcs ${sourcesJson} \
              '.skills // {} | to_entries[] | select(.value.source as $s | $srcs[0] | index($s)) | .key' \
              "$lockFile" 2>/dev/null || true)
          fi

          # Newline-delimited throughout: a directory name containing a space would
          # otherwise word-split into two rm targets, one of which can collide with
          # a legitimately owned name.
          unowned=""
          for path in "$skillsDir"/*; do
            [ -d "$path" ] || continue
            name=''${path##*/}
            if ! printf '%s\n' "$owned" | grep -qxF "$name"; then
              unowned="$unowned$name
    "
            fi
          done

          if [ -n "$unowned" ] && [ -z "$owned" ]; then
            echo "  ⚠ opencode skills: no declared skill resolved from $lockFile, refusing to prune"
          elif [ -n "$unowned" ]; then
            if [ "${lib.boolToString config.home.ai.opencodeSkillsPrune}" = "true" ]; then
              printf '%s' "$unowned" | while IFS= read -r name; do
                [ -n "$name" ] || continue
                run rm -rf "$skillsDir/$name"
              done
              printf "\n  ⚠  Pruned unmanaged opencode skills from %s:\n%s\n" "$skillsDir" "$unowned"
            else
              printf "\n  ⚠  Unmanaged directories under %s not from a declared source:\n%s" "$skillsDir" "$unowned"
              printf "     Set home.ai.opencodeSkillsPrune = true to delete them, or run:\n     rm -rf"
              printf '%s' "$unowned" | while IFS= read -r name; do
                [ -n "$name" ] || continue
                printf ' "%s/%s"' "$skillsDir" "$name"
              done
              printf "\n\n"
            fi
          fi
        fi
  '';
}

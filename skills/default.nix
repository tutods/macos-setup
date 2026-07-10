{
  config,
  pkgs,
  lib,
  ...
}: let
  commonManifest = builtins.readFile ./manifest.txt;
  extra = config.home.ai.extraSkillsManifest;
  combinedContent =
    commonManifest
    + (
      if extra != ""
      then "\n" + extra
      else ""
    );
  combinedManifest = pkgs.writeText "ai-skills-manifest" combinedContent;
  manifestHash = builtins.hashString "sha256" combinedContent;

  localSkills = ["llm-council" "content-writer" "ts-strict-audit" "conventional-commit" "open-pr"];
in {
  # Deploy local skills to both the open agent-skills standard location and Claude Code.
  # Each entry becomes a Nix store symlink — force=true replaces existing directories.
  home.file =
    lib.listToAttrs (lib.concatMap (name: [
        {
          name = ".agents/skills/${name}";
          value = {
            source = ./local/${name};
            force = true;
          };
        }
        {
          name = ".claude/skills/${name}";
          value = {
            source = ./local/${name};
            force = true;
          };
        }
      ])
      localSkills)
    // {
      # CONNECTORS.md — referenced by skills from anthropics/knowledge-work-plugins
      # via ../../CONNECTORS.md (resolves from ~/.agents/skills/<name>/ to ~/.agents/)
      ".agents/CONNECTORS.md".source = ./CONNECTORS.md;
    };

  home.activation.aiSkillsSync = lib.hm.dag.entryAfter ["writeBoundary" "aiInit"] ''
    stamp="$HOME/.config/ai/.skills-sync-hash"
    log="$HOME/.cache/ai-skills-install.log"
    mkdir -p "$HOME/.config/ai" "$HOME/.cache"

    if [ -f "$stamp" ] && [ "$(cat "$stamp")" = "${manifestHash}" ]; then
      echo "↣ AI skills up to date"
    else
      export PATH="${pkgs.git}/bin:${pkgs.nodejs}/bin:$PATH"
      # Trigger npx skills "Agent detected" non-interactive mode
      export CLAUDECODE=1
      export AI_AGENT=claude-code_agent

      # Read manifest into array before iterating (avoids stdin contention with npx)
      entries=()
      while IFS= read -r raw; do
        clean=$(printf '%s' "$raw" | sed 's/#.*//' | xargs)
        [ -n "$clean" ] && entries+=("$clean")
      done < "${combinedManifest}"

      printf "↣ Syncing AI skills (%d sources)...\n" "''${#entries[@]}" | tee -a "$log"
      ok=0; fail=0
      for entry in "''${entries[@]}"; do
        printf "  ▸ npx skills add %s -g -a claude-code -a opencode -y\n" "$entry" | tee -a "$log"
        if npx skills add $entry -g -a claude-code -a opencode -y </dev/null >>"$log" 2>&1; then
          ok=$((ok+1))
        else
          printf "    warning: failed: %s\n" "$entry" | tee -a "$log"
          fail=$((fail+1))
        fi
      done
      printf "↣ Skills sync: %d ok, %d failed (log: %s)\n" "$ok" "$fail" "$log"

      # Only stamp hash if fully successful (retry on next rebuild if any failed)
      [ "$fail" -eq 0 ] && printf "%s" "${manifestHash}" > "$stamp"
    fi
  '';
}

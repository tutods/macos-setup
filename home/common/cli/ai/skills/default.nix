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
in {
  home.activation.aiSkillsSync = lib.hm.dag.entryAfter ["writeBoundary"] ''
    stamp="$HOME/.config/ai/.skills-sync-hash"
    log="$HOME/.cache/ai-skills-install.log"
    mkdir -p "$HOME/.config/ai" "$HOME/.cache"

    # Sync local skills manually
    mkdir -p "$HOME/.agents/skills/llm-council"
    cp -f "${./llm-council/SKILL.md}" "$HOME/.agents/skills/llm-council/SKILL.md"
    mkdir -p "$HOME/.agents/skills/content-writer"
    cp -f "${./content-writer/SKILL.md}" "$HOME/.agents/skills/content-writer/SKILL.md"
    cp -f "${./content-writer/blocklist.md}" "$HOME/.agents/skills/content-writer/blocklist.md"
    cp -f "${./content-writer/templates.md}" "$HOME/.agents/skills/content-writer/templates.md"
    mkdir -p "$HOME/.claude/skills"
    ln -sfn "$HOME/.agents/skills/llm-council" "$HOME/.claude/skills/llm-council"
    ln -sfn "$HOME/.agents/skills/content-writer" "$HOME/.claude/skills/content-writer"

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
        printf "  ▸ npx skills add %s -g -a claude-code -a opencode -a github-copilot -y\n" "$entry" | tee -a "$log"
        if npx skills add $entry -g -a claude-code -a opencode -a github-copilot -y </dev/null >>"$log" 2>&1; then
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

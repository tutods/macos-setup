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
  programs.fish.functions.ai-skills-sync = {
    description = "Install AI skills from manifest into Claude Code and opencode";
    body = ''
      set -l manifest "${combinedManifest}"
      set -l agents_flag "-a" "claude-code" "-a" "opencode"
      set -l installed 0
      set -l failed 0

      if not test -f "$manifest"
        echo "Skills manifest not found at $manifest"
        return 1
      end

      while read -l line
        set -l line (string trim "$line")
        if test -z "$line"; or string match -q '#*' "$line"; continue; end

        set -l clean_line (string replace -r '#.*' "" -- "$line")
        set -l clean_line (string trim "$clean_line")
        if test -z "$clean_line"; continue; end

        set -l parts (string split " " -- $clean_line)
        echo "▸ npx skills add $parts -g $agents_flag -y"
        if npx skills add $parts -g $agents_flag -y 2>&1
          set installed (math $installed + 1)
        else
          echo "  ⚠ Failed: $clean_line"
          set failed (math $failed + 1)
        end
      end < "$manifest"

      echo ""
      echo "Skills install complete: $installed succeeded, $failed failed"
    '';
  };

  home.activation.aiSkillsSync = lib.hm.dag.entryAfter ["writeBoundary"] ''
    stamp="$HOME/.config/ai/.skills-sync-hash"
    manifest_hash="${manifestHash}"

    mkdir -p "$HOME/.config/ai"

    # Sync local skills manually
    mkdir -p "$HOME/.agents/skills/llm-council"
    cp -f "${./llm-council/SKILL.md}" "$HOME/.agents/skills/llm-council/SKILL.md"
    mkdir -p "$HOME/.claude/skills"
    ln -sfn "$HOME/.agents/skills/llm-council" "$HOME/.claude/skills/llm-council"
    mkdir -p "$HOME/.config/opencode/skills"
    ln -sfn "$HOME/.agents/skills/llm-council" "$HOME/.config/opencode/skills/llm-council"


    if [ ! -f "$stamp" ] || [ "$(cat "$stamp")" != "$manifest_hash" ]; then
      echo "↣ AI skills sync (manifest changed)"
      if command -v fish > /dev/null 2>&1; then
        # non-fatal: skills sync failure doesn't abort activation
        fish -c "ai-skills-sync" \
          && echo "$manifest_hash" > "$stamp" \
          || echo "  ⚠ ai-skills-sync failed (non-fatal)"
      else
        echo "  ⚠ fish not found, skipping skills sync (non-fatal)"
        echo "$manifest_hash" > "$stamp"
      fi
    else
      echo "↣ AI skills up to date"
    fi
  '';
}

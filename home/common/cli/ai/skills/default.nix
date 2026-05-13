{pkgs, ...}: let
  manifest = ./manifest.txt;
in {
  programs.fish.functions.ai-skills-sync = {
    body = ''
      set -l manifest "${manifest}"
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

        echo "▸ npx skills add $clean_line -g $agents_flag -y"
        if npx skills add $clean_line -g $agents_flag -y 2>&1
            set installed (math $installed + 1)
        else
            echo "  ⚠ Failed: $clean_line"
            set failed (math $failed + 1)
        end
      end < "$manifest"

      echo ""
      echo "Skills install complete: $installed succeeded, $failed failed"
    '';
    description = "Install AI skills from manifest into Claude Code and opencode";
  };
}

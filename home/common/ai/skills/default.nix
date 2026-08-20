# In-repo skill sources, shared across every role. See docs/ai-setup.md.
{
  aiLib,
  config,
  lib,
  ...
}: {
  imports = [
    (aiLib.mkLocalSkills {
      inherit lib;
      label = "common";
      dir = ./local;
      names = [
        "llm-council"
        "content-writer"
        "unslop"
        "ts-strict-audit"
        "conventional-commit"
        "open-pr"
        "review-pr"
        "pr-feedback"
        "deep-review"
        "ui-iterate"
        "obsidian-vault"
        "nix-setup"
        "ts-conventions"
        "react-conventions"
        "api-conventions"
        "testing-conventions"
        "dependency-hygiene"
      ];
    })
  ];

  # Reports rather than deletes, a stray directory may be a hand-written skill.
  home.activation.customSkillsAudit = lib.hm.dag.entryAfter ["writeBoundary" "linkGeneration"] ''
    dest="$HOME/.claude/skills"
    managed=" ${lib.concatStringsSep " " config.home.ai.customSkills} "
    stray=""

    for path in "$dest"/*; do
      [ -e "$path" ] || continue
      name=$(basename "$path")
      case "$managed" in
        *" $name "*) ;;
        *) stray="$stray $name" ;;
      esac
    done

    if [ -n "$stray" ]; then
      printf "\n  ⚠  Unmanaged skills in ~/.claude/skills:\n"
      for name in $stray; do printf "       %s\n" "$name"; done
      printf "  These predate the move to plugins (or were added by hand).\n"
      printf "  Remove the ones you don't want with:\n"
      printf "    rm -rf%s\n\n" "$(for name in $stray; do printf " ~/.claude/skills/%s" "$name"; done)"
    fi
  '';
}

# ── Custom skills — shared across every role ──────────────────────────────────
#
# In-repo skill sources only. Everything else comes from a Claude Code plugin
# marketplace (home/common/cli/ai/tools/claude/plugins.nix).
#
# Installed as real directories under ~/.claude/skills, not store symlinks —
# see lib/ai.nix:mkLocalSkills for why. Role-specific custom skills live in
# home/roles/<role>/ai/skills/local/ and are installed the same way.
#
{
  config,
  pkgs,
  lib,
  ...
}: let
  ai = import ../lib/ai.nix {inherit pkgs;};
in {
  imports = [
    (ai.mkLocalSkills {
      inherit lib;
      label = "common";
      dir = ./local;
      names = [
        "llm-council"
        "content-writer"
        "ts-strict-audit"
        "conventional-commit"
        "open-pr"
        "deep-review"
        "ui-iterate"

        # Stack conventions — skills, not always-on instructions, so they load
        # only when the work is actually TypeScript/React/API/testing/deps.
        "ts-conventions"
        "react-conventions"
        "api-conventions"
        "testing-conventions"
        "dependency-hygiene"
        # Vendored (MIT) — kadajett/agent-nestjs-skills is not a plugin
        # marketplace, so this cannot arrive as a plugin. NestJS is a primary
        # backend framework here and nothing else covers it. Provenance is in
        # the SKILL.md frontmatter.
        "nestjs-best-practices"
      ];
    })
  ];

  # ~/.claude/skills used to hold whatever `npx skills add` had dropped there.
  # Now only custom skills belong in it — external ones ship inside their
  # plugin. Anything else is a leftover shadowing a plugin's copy, so report it
  # rather than delete it: the directory may be a hand-written skill.
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

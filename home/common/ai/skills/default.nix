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
        "seo-audit"
        "harness-engineer"
      ];
    })
    # Fetched, not committed: the user does not want orca's skill content
    # living in this repo's git history. To bump the pin: run
    # `git ls-remote https://github.com/stablyai/orca HEAD`, review the diff
    # upstream, then update rev + hash together.
    (aiLib.mkFetchedSkills {
      inherit lib;
      label = "orca";
      owner = "stablyai";
      repo = "orca";
      rev = "976e05c0c81cff2b4ed038b9d847834ad7c8ba7b";
      hash = "sha256-k2oV/OmwrGdc8DLEDnM5lg4lRs5J4w0kRoW/j+nzsGA=";
      subdir = "skills";
      names = ["orchestration" "orca-cli"];
    })
  ];

  # A skill name declared by more than one mkLocalSkills/mkFetchedSkills
  # instance (common + roles) would deploy whichever localSkills-*/
  # fetchedSkills-* copy happened to run last, an order the activation DAG
  # leaves unspecified. Fail the build instead.
  assertions = let
    skills = config.home.ai.customSkills;
    dupes = lib.unique (lib.filter (n: lib.count (x: x == n) skills > 1) skills);
  in [
    {
      assertion = dupes == [];
      message = "home.ai.customSkills: duplicate skill name(s) across common/roles: ${lib.concatStringsSep ", " dupes}";
    }
  ];

  # Deletes any real directory in ~/.claude/skills this repo does not declare, so
  # a renamed or removed skill actually disappears instead of staying loaded.
  # Symlinks are left alone: they point at non-Nix tooling (e.g. ~/.agents/skills).
  # Runs after every localSkills-*/fetchedSkills-* copy (entryBetween in
  # lib/ai.nix:mkSkillCopy, shared by mkLocalSkills and mkFetchedSkills).
  home.activation.customSkillsReconcile = lib.hm.dag.entryAfter ["writeBoundary" "linkGeneration"] ''
    dest="$HOME/.claude/skills"
    if [ -d "$dest" ]; then
      managed=" ${lib.concatStringsSep " " config.home.ai.customSkills} "
      removed=""

      for path in "$dest"/*; do
        [ -d "$path" ] || continue
        [ -L "$path" ] && continue
        name=$(basename "$path")
        case "$managed" in
          *" $name "*) ;;
          *)
            rm -rf "$path"
            removed="$removed $name"
            ;;
        esac
      done

      if [ -n "$removed" ]; then
        printf "\n  ⚠  Removed unmanaged skills from ~/.claude/skills:%s\n\n" "$removed"
      fi
    fi
  '';
}

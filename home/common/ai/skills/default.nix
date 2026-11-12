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
      dir = ./local;
      names = ["llm-council" "obsidian-vault" "unslop"];
      claudeOnly = ["llm-council"];
    })
  ];

  # A skill name declared by more than one mkLocalSkills instance (common +
  # roles) would deploy whichever localSkills-* copy happened to run last, an
  # order the activation DAG leaves unspecified. Fail the build instead.
  assertions = let
    skills = config.home.ai.customSkills;
    dupes = lib.unique (lib.filter (n: lib.count (x: x == n) skills > 1) skills);
  in [
    {
      assertion = dupes == [];
      message = "home.ai.customSkills: duplicate skill name(s) across common/roles: ${lib.concatStringsSep ", " dupes}";
    }
  ];

  # Deletes any undeclared entry in ~/.claude/skills, directory or symlink, so a
  # renamed or removed skill actually disappears instead of staying loaded.
  # Nix-managed skills are always real copied directories, so a symlink there
  # is foreign by construction (most often an `npx skills`-style install
  # pointing at ~/.agents/skills).
  # Runs after the localSkills copy (entryBetween in lib/ai.nix:mkLocalSkills).
  home.activation.customSkillsReconcile = lib.hm.dag.entryAfter ["writeBoundary" "linkGeneration"] ''
    dest="$HOME/.claude/skills"
    if [ -d "$dest" ]; then
      managed=" ${lib.concatStringsSep " " (config.home.ai.customSkills ++ config.home.ai.externallyManagedSkills)} "
      removed=""

      for path in "$dest"/*; do
        [ -L "$path" ] || [ -d "$path" ] || continue
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

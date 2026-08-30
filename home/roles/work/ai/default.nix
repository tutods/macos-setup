{
  aiLib,
  lib,
  ...
}: {
  imports = [
    (aiLib.mkLocalSkills {
      inherit lib;
      label = "work";
      dir = ./skills/local;
      names = ["acli" "babysit-prs" "deep-review-prs" "implement-ticket" "work-stack"];
    })
  ];

  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  # The vault syncs to this machine via its private git repo; personal-context
  # folders (freelance clients, personal projects) stay out of every session's
  # context. The folders remain on disk and readable, this only scopes the
  # SessionStart index.
  home.ai.vaultFolders = ["Conventions" "Lessons" "Decisions" "Process" "Notes"];
}

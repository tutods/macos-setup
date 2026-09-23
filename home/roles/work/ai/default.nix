{...}: {
  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  # Work plugins (mp-ai-workbench, mp-fe-design) are project-scoped: the
  # frontend, workspace and ai-workbench repos enable them in their own
  # .claude/settings.json instead of here.

  # The vault syncs to this machine via its private git repo; personal-context
  # folders (freelance clients, personal projects) stay out of the declared
  # scope vault-lint audits against. The folders remain on disk and readable,
  # this only declares what is work-relevant.
  home.ai.vaultFolders = ["Conventions" "Lessons" "Decisions" "Process" "Notes"];
}

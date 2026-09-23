{...}: {
  home.ai.extraInstructions = builtins.readFile ./instructions.md;

  # Mindera's internal marketplace. Deliberately unpinned, unlike the shared
  # third-party pins in home/common/ai/plugins.nix: it is the employer's own
  # repo, was installed on this machine with autoUpdate, and tracking the
  # team's HEAD is the point. Work-scoped, so it lives here, not in common.
  home.ai.marketplaces = {
    ai-workbench = "Mindera-People/ai-workbench";
  };
  home.ai.plugins = [
    "mp-ai-workbench@ai-workbench"
    "mp-fe-design@ai-workbench"
  ];

  # The vault syncs to this machine via its private git repo; personal-context
  # folders (freelance clients, personal projects) stay out of the declared
  # scope vault-lint audits against. The folders remain on disk and readable,
  # this only declares what is work-relevant.
  home.ai.vaultFolders = ["Conventions" "Lessons" "Decisions" "Process" "Notes"];
}

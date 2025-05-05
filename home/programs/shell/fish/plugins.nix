[
  # fzf.fish - Powerful fzf integration for directory navigation with tab completion
  {
    name = "fzf.fish";
    src = pkgs.fetchFromGitHub {
      owner = "PatrickF1";
      repo = "fzf.fish";
      rev = "v9.2";  # Use a specific version for stability
      sha256 = "sha256-XmR5v3CMfcSKnP0YJkJocuYN1qbQgJRYZZH33SJJ9Gc=";
    };
  }
  
  # Add more fish plugins here as needed
]
{
  programs.git = {
    enable = true;
    userEmail = "daniel.a.sousa@mindera.com";
    userName = "Daniel Sousa";
    diff-so-fancy.enable = true;
    lfs.enable = true;
    extraConfig = {
      init = {
        defaultBranch = "main";
      };
      # merge = {
      #   conflictStyle = "diff3";
      #   tool = "meld";
      # };
      pull = {
        rebase = true;
      };
    };
  };
}
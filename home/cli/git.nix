{ ... }:

{
  programs.git = {
    enable = true;
    userEmail = "jdaniel.asousa@gmail.com";
    userName = "Daniel Sousa @TutoDS";
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
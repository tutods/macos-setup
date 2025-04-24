{ ... }:

{
  programs.git = {
    enable = true;

    userName = "Daniel Sousa @TutoDS";
    userEmail = "jdaniel.asousa@gmail.com";

    lfs = {
      enable = true;
    };

    diff-so-fancy = {
      enable = true;
    };

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
      push = {
        autoSetupRemote = true;
      };
    };

    ignores = [
      ".DS_Store"
      ".env"
      "node_modules"
    ];

    difftastic = {
      enable = true;
      display = "inline";
    };
  };

  programs.gh.enable = true;
}
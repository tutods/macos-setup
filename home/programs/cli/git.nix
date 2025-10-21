{ ... }:

{
  programs.diff-so-fancy = {
    enable = true;
    enableGitIntegration = true;
  };
  
  programs.git = {
    enable = true;

    settings = {
      user = {
        email = "jdaniel.asousa@gmail.com";
        name = "Daniel Sousa @TutoDS";
      };

      extraConfig = {
        init = {
          defaultBranch = "main";
        };
        # merge = {
        #   conflictStyle = "diff3";
        #   tool = "meld";
        # };
        push = {
          autoSetupRemote = true;
        };
        pull = {
          rebase = true;
        };
      };
    };

    lfs.enable = true;
  };
}

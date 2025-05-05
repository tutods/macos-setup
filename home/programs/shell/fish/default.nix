{ config, pkgs, ... }:

{
  imports = [
    ./plugins.nix
    ./extra.nix
    # ./completions.nix
  ];

  programs.bash = {
    initExtra = ''
      if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
      then
        shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
        exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
      fi
    '';
  };

  programs.fish = {
    enable = true;
    shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;

    interactiveShellInit = ''
      bind \ew backward-kill-line
      bind \cf npm_scripts_autocomplete

      # Configure fzf.fish bindings
      fzf_configure_bindings

      # Set directory preview command for fzf
      set fzf_preview_dir_cmd eza --all --color=always
      
      # Initialize zoxide for Fish shell
      zoxide init fish | source
      
      # Bind Tab key to our custom fzf cd completion function
      bind \t '__fzf_cd_completion; or commandline -f complete'
    '';

    # Plugins are now defined in plugins.nix

    # plugins = [
    #   #   # fishPlugins.done
    #   # pkgs.fishPlugins.fzf-fish
    #   # pkgs.fishPlugins.pisces
    #   # fishPlugins.autopair
    #   # fishPlugins.hydro
    # ];

    # plugins = [
    #   # {
    #   #   name = "fzf-fish";
    #   #   src = pkgs.fishPlugins.fzf-fish;
    #   # }
    #   {
    #     name = "z";
    #     src = pkgs.fishPlugins.z.src;
    #   }
    #   {
    #     name = "pisces";
    #     src = pkgs.fishPlugins.pisces.src;
    #   }
    #   {
    #     name = "puffer";
    #     src = pkgs.fishPlugins.puffer.src;
    #   }
    # ];
  };
}

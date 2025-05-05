{ config, pkgs, ... }:

{
  imports = [
    ./extra.nix
    ./plugins.nix
  ];

  # users.defaultUserShell = pkgs.fish;

  # programs.bash = {
  #   interactiveShellInit = ''
  #     if [[ $(${pkgs.procps}/bin/ps --no-header --pid=$PPID --format=comm) != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
  #     then
  #       shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
  #       exec ${pkgs.fish}/bin/fish $LOGIN_OPTION
  #     fi
  #   '';
  # };


  programs.fish = {
    enable = true;
      shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;

    interactiveShellInit = ''
      bind \ew backward-kill-line
      bind \cf npm_scripts_autocomplete
      
      # Set up fzf for Fish
      set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
      set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
      set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
      set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
      
      # Enable fzf key bindings if available
      if functions -q fzf_key_bindings
        fzf_key_bindings
      end
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

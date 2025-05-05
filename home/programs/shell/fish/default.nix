{ config, pkgs, ... }:

{
  imports = [
    ./extra.nix
  ];

  programs.fish = {
    enable = true;
    shellAliases = import ./alias.nix;
    shellAbbrs = import ./abbrs.nix;
    functions = import ./functions.nix;

    plugins = [
      {
        name = "plugin-git";
        src = pkgs.fishPlugins.plugin-git.src;
      }
      {
        name = "pisces";
        src = pkgs.fishPlugins.pisces.src;
      }
    ];

    interactiveShellInit = ''
      bind \ew backward-kill-line
      bind \cf npm_scripts_autocomplete

      # Configure fzf.fish bindings
      #fzf_configure_bindings

      # Set directory preview command for fzf
      #set fzf_preview_dir_cmd eza --all --color=always
      
      # Bind Tab key to our custom fzf cd completion function
      bind \t '__fzf_cd_completion; or commandline -f complete'
    '';
  };
}

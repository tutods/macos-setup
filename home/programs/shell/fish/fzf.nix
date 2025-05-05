{ pkgs, ... }:

{
  programs.fish = {
    interactiveShellInit = ''
      # Set up fzf for Fish
      set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
      set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
      set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
      set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
      
      # Enable fzf key bindings
      fzf_key_bindings
    '';
  };
}

{ pkgs, ... }:

{
  programs.fish = {
    # Custom completions configuration
    interactiveShellInit = ''
      # Case-insensitive tab completion (equivalent to matcher-list in ZSH)
      set -g fish_complete_path $fish_complete_path ~/.config/fish/completions
      
      # Configure fzf for directory previews
      function __fzf_cd_preview
        eza --color=always --icons $argv
      end
      
      # Set up fzf for Fish
      set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
      set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
      set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'
      set -gx FZF_DEFAULT_OPTS '--height 40% --layout=reverse --border'
      
      # Configure fzf preview for cd command
      set -gx FZF_ALT_C_OPTS "--preview='__fzf_cd_preview {}'"
      
      # Enable fzf key bindings if available
      if type -q fzf_key_bindings
        fzf_key_bindings
      end
      
      # Custom key binding for directory navigation (Alt+C)
      bind \ec 'fzf-cd-widget'
      
      # Enable Ctrl+T for file selection with fzf
      bind \ct 'fzf-file-widget'
      
      # Enable Ctrl+R for history search with fzf
      bind \cr 'fzf-history-widget'
    '';
  };
}

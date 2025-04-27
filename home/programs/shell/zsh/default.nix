{ config, lib, pkgs, ... }:

{
  imports = [
    ./extra.nix
  ];

  programs.zsh = {
    enable = true;
    autocd = true;
    dotDir = ".config/zsh";
    
    enableCompletion = true;
    syntaxHighlighting.enable = true;
    autosuggestion.enable = true;

    # History configuration
    history = {
      size = 5000;
      save = 5000;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
      share = true;
      path = "${config.home.homeDirectory}/.zsh_history";
    };
    
    shellAliases = import ./alias.nix;

    # Initialize extra tools
    initContent = ''
      # Set the directory to store zinit and plugins
      ZINIT_HOME="''${XDG_DATA_HOME:-''${HOME}/.local/share}/zinit/zinit.git"

      # Download zinit if it's not already installed
      if [ ! -d "$ZINIT_HOME" ]; then
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
      fi

      # Source/Load zinit
      source "''${ZINIT_HOME}/zinit.zsh"

      # Add in zsh plugins
      #zinit light zsh-users/zsh-syntax-highlighting
      #zinit light zsh-users/zsh-completions
      #zinit light zsh-users/zsh-autosuggestions
      zinit light Aloxaf/fzf-tab
      zinit light hlissner/zsh-autopair

      # Add in snippets
      zinit snippet OMZL::git.zsh
      zinit snippet OMZP::git
      zinit snippet OMZP::alias-finder
      zinit snippet OMZP::brew
      zinit snippet OMZP::command-not-found

      # Load completions
      autoload -Uz compinit && compinit

      zinit cdreplay -q

      # Keybindings
      bindkey "^[[A" history-search-backward
      bindkey "^[[B" history-search-forward
      bindkey "\ew" backward-kill-line

      # FZF Tab styling
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always --icons $realpath'

      function commt() {
        git add .
        git commit -m "$1"
        git push
      }

      function stashPull() {
        git stash
        git pull
        git stash pop
      }

      function goMaster() {
        git checkout master
        git pull
      }

      function goMain() {
        git checkout main
        git pull
      }
    '';
  };
}
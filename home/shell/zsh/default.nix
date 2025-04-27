{ config, pkgs, ... }:

{
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    
    # Enable syntax highlighting
    syntaxHighlighting = {
      enable = true;
      highlighters = [ "main" "brackets" "pattern" "cursor" "regexp" "root" "line" ];
    };

    # Enable fish-like autosuggestions
    autosuggestions = {
      enable = true;
      strategy = [ "history" "completion" ];
      highlightStyle = "fg:8";
    };

    # Shell integration
    shellInit = ''
      # Set the directory to store zinit and plugins
      ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

      # Download zinit if it's not already installed
      if [ ! -d "$ZINIT_HOME" ]; then
        mkdir -p "$(dirname "$ZINIT_HOME")"
        git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
      fi

      # Source/Load zinit
      source "${ZINIT_HOME}/zinit.zsh"

      # Add in zsh plugins
      zinit light zsh-users/zsh-syntax-highlighting
      zinit light zsh-users/zsh-completions
      zinit light zsh-users/zsh-autosuggestions
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
    '';

    # Shell options
    shellOptions = [
      "AUTO_CD"              # Change directory without cd
      "EXTENDED_GLOB"        # Extended globbing
      "NO_CASE_GLOB"         # Case insensitive globbing
      "NUMERIC_GLOB_SORT"    # Sort filenames numerically
      "HIST_IGNORE_ALL_DUPS" # Remove older duplicate entries
      "HIST_REDUCE_BLANKS"   # Remove superfluous blanks
      "HIST_SAVE_NO_DUPS"    # Don't write duplicate entries
      "HIST_VERIFY"          # Don't execute immediately upon history expansion
      "SHARE_HISTORY"        # Share history between sessions
      "EXTENDED_HISTORY"     # Save timestamp and duration
      "INC_APPEND_HISTORY"   # Add commands immediately
      "HIST_EXPIRE_DUPS_FIRST" # Expire duplicate entries first
    ];

    # Key bindings
    keybindings = {
      "^[[A" = "history-search-backward";
      "^[[B" = "history-search-forward";
      "\ew" = "backward-kill-line";
    };

    # History configuration
    history = {
      size = 5000;
      save = 5000;
      ignoreSpace = true;
      ignoreDups = true;
      ignoreAllDups = true;
      expireDupsFirst = true;
      share = true;
      extended = true;
      path = "$HOME/.zsh_history";
    };

    # Completion styling
    completionInit = ''
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always --icons $realpath'
    '';

    # Aliases
    shellAliases = {
      ls = "eza --color=always --icons";
      bsearch = "brew search";
      work = "cd ~/Developer";
    };

    # Functions
    functions = {
      commt = ''
        git add .
        git commit -m "$1"
        git push
      '';
      stashPull = ''
        git stash
        git pull
        git stash pop
      '';
      goMaster = ''
        git checkout master
        git pull
      '';
      goMain = ''
        git checkout main
        git pull
      '';
    };
  };
} 
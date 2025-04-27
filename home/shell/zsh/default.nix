{ config, lib, pkgs, ... }:

{
  imports = [
    ./extra.nix
  ];

  programs.zsh = {
    enable = true;
    autocd = true;
    dotDir = ".config/zsh";
    enableAutosuggestions = true;
    enableCompletion = true;
    syntaxHighlighting.enable = true;

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

    # initExtra = ''
    #   # Keybindings
    #   # Bind up/down arrow keys for history search
    #   bindkey "^[[A" history-search-backward
    #   bindkey "^[[B" history-search-forward
    #   # Bind Cmd+Backspace to delete word backward
    #   bindkey "\ew" backward-kill-line
    # '';

    # Initialize extra tools
    initExtra = ''
      # Keybindings
      bindkey "^[[A" history-search-backward
      bindkey "^[[B" history-search-forward
      bindkey "\ew" backward-kill-line

      # FZF Tab styling
      zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
      zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
      zstyle ':completion:*' menu no
      zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons $realpath'
      zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always --icons $realpath'
    '';

    # Custom functions
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

    # plugins = with pkgs; [
    #   {
    #     name = "agkozak-zsh-prompt";
    #     src = fetchFromGitHub {
    #       owner = "agkozak";
    #       repo = "agkozak-zsh-prompt";
    #       rev = "v3.7.0";
    #       sha256 = "1iz4l8777i52gfynzpf6yybrmics8g4i3f1xs3rqsr40bb89igrs";
    #     };
    #     file = "agkozak-zsh-prompt.plugin.zsh";
    #   }
    #   {
    #     name = "formarks";
    #     src = fetchFromGitHub {
    #       owner = "wfxr";
    #       repo = "formarks";
    #       rev = "8abce138218a8e6acd3c8ad2dd52550198625944";
    #       sha256 = "1wr4ypv2b6a2w9qsia29mb36xf98zjzhp3bq4ix6r3cmra3xij90";
    #     };
    #     file = "formarks.plugin.zsh";
    #   }
    #   {
    #     name = "zsh-syntax-highlighting";
    #     src = fetchFromGitHub {
    #       owner = "zsh-users";
    #       repo = "zsh-syntax-highlighting";
    #       rev = "0.6.0";
    #       sha256 = "0zmq66dzasmr5pwribyh4kbkk23jxbpdw4rjxx0i7dx8jjp2lzl4";
    #     };
    #     file = "zsh-syntax-highlighting.zsh";
    #   }
    #   {
    #     name = "zsh-abbrev-alias";
    #     src = fetchFromGitHub {
    #       owner = "momo-lab";
    #       repo = "zsh-abbrev-alias";
    #       rev = "637f0b2dda6d392bf710190ee472a48a20766c07";
    #       sha256 = "16saanmwpp634yc8jfdxig0ivm1gvcgpif937gbdxf0csc6vh47k";
    #     };
    #     file = "abbrev-alias.plugin.zsh";
    #   }
    #   {
    #     name = "zsh-autopair";
    #     src = fetchFromGitHub {
    #       owner = "hlissner";
    #       repo = "zsh-autopair";
    #       rev = "34a8bca0c18fcf3ab1561caef9790abffc1d3d49";
    #       sha256 = "1h0vm2dgrmb8i2pvsgis3lshc5b0ad846836m62y8h3rdb3zmpy1";
    #     };
    #     file = "autopair.zsh";
    #   }
    # ];

    # Additional plugins through Home Manager
    plugins = [
      {
        name = "zsh-autopair";
        src = pkgs.fetchFromGitHub {
          owner = "hlissner";
          repo = "zsh-autopair";
          rev = "34a8bca0c18fcf3ab1561caef9790abffc1d3d49";
          sha256 = "1h0vm2dgrmb8i2pvsgis3lshc5b0ad846836m62y8h3rdb3zmpy1";
        };
      }
      {
        name = "fzf-tab";
        src = pkgs.fetchFromGitHub {
          owner = "Aloxaf";
          repo = "fzf-tab";
          rev = "master";
          sha256 = "0000000000000000000000000000000000000000000000000000";  # You'll need to update this
        };
      }
    ];
  };
}

# { config, pkgs, ... }:

# {
#   programs.zsh = {
#     enable = true;
#     enableCompletion = true;
#     autosuggestion.enable = true;
    
#     # Enable syntax highlighting
#     syntaxHighlighting = {
#       enable = true;
#       highlighters = [ "main" "brackets" "pattern" "cursor" "regexp" "root" "line" ];
#     };

#     # Shell integration
#     initExtra = ''
#       # Set the directory to store zinit and plugins
#       ZINIT_HOME="''${XDG_DATA_HOME:-$HOME/.local/share}/zinit/zinit.git"

#       # Download zinit if it's not already installed
#       if [ ! -d "$ZINIT_HOME" ]; then
#         mkdir -p "$(dirname "$ZINIT_HOME")"
#         git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
#       fi

#       # Source/Load zinit
#       source "$ZINIT_HOME/zinit.zsh"

#       # Add in zsh plugins
#       zinit light zsh-users/zsh-syntax-highlighting
#       zinit light zsh-users/zsh-completions
#       zinit light zsh-users/zsh-autosuggestions
#       zinit light Aloxaf/fzf-tab
#       zinit light hlissner/zsh-autopair

#       # Add in snippets
#       zinit snippet OMZL::git.zsh
#       zinit snippet OMZP::git
#       zinit snippet OMZP::alias-finder
#       zinit snippet OMZP::brew
#       zinit snippet OMZP::command-not-found

#       # Load completions
#       autoload -Uz compinit && compinit

#       zinit cdreplay -q

#       # Key bindings
#       bindkey '^[[A' history-search-backward
#       bindkey '^[[B' history-search-forward
#       bindkey '^ew' backward-kill-line

#       # Custom functions
#       function commt() {
#         git add .
#         git commit -m "$1"
#         git push
#       }

#       function stashPull() {
#         git stash
#         git pull
#         git stash pop
#       }

#       function goMaster() {
#         git checkout master
#         git pull
#       }

#       function goMain() {
#         git checkout main
#         git pull
#       }
#     '';

#     # Shell options
#     setOptions = [
#       "AUTO_CD"              # Change directory without cd
#       "EXTENDED_GLOB"        # Extended globbing
#       "NO_CASE_GLOB"         # Case insensitive globbing
#       "NUMERIC_GLOB_SORT"    # Sort filenames numerically
#       "HIST_IGNORE_ALL_DUPS" # Remove older duplicate entries
#       "HIST_REDUCE_BLANKS"   # Remove superfluous blanks
#       "HIST_SAVE_NO_DUPS"    # Don't write duplicate entries
#       "HIST_VERIFY"          # Don't execute immediately upon history expansion
#       "SHARE_HISTORY"        # Share history between sessions
#       "EXTENDED_HISTORY"     # Save timestamp and duration
#       "INC_APPEND_HISTORY"   # Add commands immediately
#       "HIST_EXPIRE_DUPS_FIRST" # Expire duplicate entries first
#     ];

#     # History configuration
#     history = {
#       size = 5000;
#       save = 5000;
#       ignoreSpace = true;
#       ignoreDups = true;
#       ignoreAllDups = true;
#       expireDupsFirst = true;
#       share = true;
#       extended = true;
#       path = "$HOME/.zsh_history";
#     };

#     # Completion styling
#     completionInit = ''
#       zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
#       zstyle ':completion:*' list-colors "''${(s.:.)LS_COLORS}"
#       zstyle ':completion:*' menu no
#       zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza --color=always --icons $realpath'
#       zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza --color=always --icons $realpath'
#     '';

#     # Aliases
#     shellAliases = {
#       ls = "eza --color=always --icons";
#       bsearch = "brew search";
#       work = "cd ~/Developer";
#     };
#   };

#   # Enable zsh-autosuggestions
#   programs.zsh-autosuggestions = {
#     enable = true;
#     strategy = [ "history" "completion" ];
#     highlightStyle = "fg:8";
#   };
# } 
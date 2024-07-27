# Git
alias g="git"
alias gst="git status -sb"
alias gp="git push"
alias gl="git pull"
alias gco="git checkout"
alias gb="git branch"
alias gaa="git add ."
alias ga="git add"
alias grh="git reset --hard"
alias gr="git reset"

# Homebrew
alias bci="brew install --cask"
alias bi="brew install"
alias bup="brew update"
alias bug="brew upgrade"
alias bcl="brew cleanup"
alias br="brew remove"
alias bsearch="brew search"

# Docker
#alias docker="podman" #-> Remove comment if you are using podman
alias dps="docker ps --format '{{.Names}}'"
alias dpst="docker ps --format 'table {{.ID}}\\t{{.Image}}\\t{{.Status}}\\t{{.Names}}'"
alias dpsl="docker ps --format='ID\t{{.ID}}\nNAME\t{{.Names}}\nIMAGE\t{{.Image}}\nPORTS\t{{.Ports}}\nCOMMAND\t{{.Command}}\nCREATED\t{{.CreatedAt}}\nSTATUS\t{{.Status}}\n'"
alias dvunused="docker volume ls -q -f 'dangling=true'"

# Navigation Alias
alias work="cd ~/Developer"
alias home="cd ~"
alias ..="cd .."
alias ...="cd ../.."

# Eza on LS
alias ls="eza --icons"
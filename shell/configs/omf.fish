# Path to Oh My Fish install.
set -q XDG_DATA_HOME
  and set -gx OMF_PATH "$XDG_DATA_HOME/omf"
  or set -gx OMF_PATH "$HOME/.local/share/omf"

# Load Oh My Fish configuration.
source $OMF_PATH/init.fish

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
 
function goMain
    git checkout main
    git pull
end
 
function goMaster
    git checkout master
    git pull
end
 
function goBranch
    git checkout "$argv"
    git pull
end
 
function commt
    git add .
    git commit -m "$argv"
    git push
end

alias bci="brew install --cask"
alias bi="brew install"
alias bup="brew update"
alias bug="brew upgrade"
alias bcl="brew cleanup"
alias br="brew remove"
alias bsearch="brew search"

alias docker="podman"
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
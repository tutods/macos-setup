#!/bin/bash

DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
OMF_FILE="$DIR/configs/omf.fish"

# Install OMF
curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish > $HOME/.local/fisher.fish
source $HOME/.local/fisher.fish
fisher install jorgebucaran/fisher

# rm -rf $HOME/.local/fisher.fish

# curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > install
# fish install --path=~/.local/share/omf --config=~/.config/omf
# Wait for the installation to complete before proceeding

# eval "$(source $HOME/.config/config.fish)"
# eval "$(source $HOME/.config/conf.d/omf.fish)"
# eval "$(fish $HOME/.local/install --path=$HOME/.local/share/omf --config=$HOME/.config/omf)"
# rm $HOME/.local/install
# eval "$(source $OMF_PATH/init.fish)"

# Copy OMF config
# cp -f $OMF_FILE ~/.config/fish/conf.d
# eval "$(source $HOME/.config/fish/config.fish)"

# Install plugins
fisher install jhillyerd/plugin-git
fisher install laughedelic/pisces
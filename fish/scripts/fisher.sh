#!/bin/bash
# Install OMF
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
source ~/.config/fish/functions/fisher.fish

fisher install jorgebucaran/fisher

# Install plugins
fisher install jhillyerd/plugin-git
fisher install laughedelic/pisces
#!/bin/bash
# Install OMF
curl https://git.io/fisher --create-dirs -sLo ~/.config/fish/functions/fisher.fish
fish -c "source ~/.config/fish/functions/fisher.fish"
fish -c "fisher install jorgebucaran/fisher"

# Install plugins
fish -c "fisher install jhillyerd/plugin-git"
fish -c "fisher install laughedelic/pisces"
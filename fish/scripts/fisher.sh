#!/bin/bash

# Install fisher
curl https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish --create-dirs -sLo ~/.config/fish/functions/fisher.fish
fish -c "source ~/.config/fish/functions/fisher.fish"
fish -c "fisher install jorgebucaran/fisher"

# Install plugins
fish -c "fisher install jhillyerd/plugin-git"
fish -c "fisher install laughedelic/pisces"
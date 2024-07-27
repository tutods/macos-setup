#!/bin/bash

# Install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# case $(basename $SHELL) in
#     fish)
#         (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.config/fish/config.fish && eval "$(/opt/homebrew/bin/brew shellenv)"
#         ;;
#     zsh)
#         (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') > $HOME/.zprofile && eval "$(/opt/homebrew/bin/brew shellenv)"
#         ;;
#     bash)
#         (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') > $HOME/.bash_profile && eval "$(/opt/homebrew/bin/brew shellenv)"
#         ;;
#     *)
#         echo "Unknown shell: $(basename $SHELL)"
#         ;;
# esac
eval "$(/usr/local/bin/brew shellenv)"


# Check if it's everything ok
brew doctor
#!/bin/bash

# Install fnm formula (if not installed)
if ! brew list 2>/dev/null | grep -q 'fnm'; then
  brew install fnm
fi

# Install lts version
echo "1) Install lts version"
fnm install --lts --corepack-enabled

# Set up for the current shell
echo "2) Setup shell environment"
case $(basename $SHELL) in
    fish)
        echo "Fish shell detected"
        echo 'fnm env --use-on-cd | source' > ~/.config/fish/conf.d/fnm.fish
        fish
        ;;
    zsh)
        echo "Zsh shell detected"
        echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
        zsh
        ;;
    bash)
        echo "Bash shell detected"
        echo 'eval "$(fnm env --use-on-cd)"' >> ~/.bashrc
        bash
        ;;
    *)
        echo "Unknown shell: $(basename $SHELL)"
        ;;
esac


# Set up for the current shell
fnm completions --log-level quiet --shell $(basename $SHELL)

# Use version
echo "3) Set default version to use"
fnm default $(fnm ls | head -n 1)

# Enable Corepack (for Yarn and PNPM)
echo "4) Enable Corepack"
corepack enable
corepack prepare pnpm@latest --activate
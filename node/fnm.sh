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
        source ~/.config/fish/conf.d/fnm.fish
        ;;
    zsh)
        echo "Zsh shell detected"
        echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
        source ~/.zshrc
        ;;
    bash)
        echo "Bash shell detected"
        echo 'eval "$(fnm env --use-on-cd)"' >> ~/.bashrc
        source ~/.bashrc
        ;;
    *)
        echo "Unknown shell: $(basename $SHELL)"
        ;;
esac

eval "$(fnm env --use-on-cd)"
# Set up for the current shell
echo "3) Setup shell completions"
fnm completions --log-level quiet --shell $(basename $SHELL)


# Enable Corepack (for Yarn and PNPM)
echo "4) Enable Corepack"
corepack enable
corepack prepare pnpm@latest --activate
#!/bin/bash

# Install fnm formula (if not installed)
if ! brew list 2>/dev/null | grep -q 'fnm'; then
  brew install fnm
fi

# Set up for the current shell
echo "1) Setup shell environment"
case $(basename $SHELL) in
    fish)
        echo "Fish shell detected"
        echo 'fnm env --use-on-cd | source' > ~/.config/fish/conf.d/fnm.fish
        source ${HOME}/.config/fish/conf.d/fnm.fish
        source ${HOME}/.config/fish/config.fish
        ;;
    zsh | bash)
        echo "${basename $SHELL} shell detected"
        echo 'eval "$(fnm env --use-on-cd)"' >> ~/.$(basename $SHELL)rc
        source ${HOME}/.$(basename $SHELL)rc
        ;;
    *)
        echo "Unknown shell: $(basename $SHELL)"
        ;;
esac

eval "$(fnm env --use-on-cd)"

# Set up for the current shell
echo "2) Setup shell completions"
fnm completions --log-level quiet --shell $(basename $SHELL)

# Install lts version
echo "3) Install lts version"
fnm install --lts --corepack-enabled

#fnm env --use-on-cd --shell "$(basename $SHELL)"
#fnm use --install-if-missing --corepack-enabled $(fnm ls | head -n 1)
echo "4) Use installed version as default"
fnm use $(fnm ls | head -n 1)

# Enable Corepack (for Yarn and PNPM)
echo "5) Enable Corepack"
corepack enable
corepack prepare pnpm@latest --activate
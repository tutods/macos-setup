#!/bin/bash

# Install fnm formula (if not installed)
if ! brew list 2>/dev/null | grep -q 'fnm'; then
  brew install fnm
fi

# Install lts version
fnm install --lts --corepack-enabled

# Set up for the current shell
if [[ $SHELL == *"fish"* ]]; then
  echo 'fnm env --use-on-cd | source' > ~/.config/fish/conf.d/fnm.fish
  fnm completions --shell fish

  # Reload the terminal
  source ~/.config/fish/conf.d/fnm.fish && fish
elif [[ $SHELL == *"bash"* ]]; then
  echo 'eval "$(fnm env --use-on-cd)"' >> ~/.bashrc
  fnm completions --shell bash
  
  # Reload the terminal
  source ~/.bashrc && bash
elif [[ $SHELL == *"zsh"* ]]; then
  echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
  fnm completions --shell zsh

  # Reload the terminal
  source ~/.zshrc && zsh
fi


# Enable completions and setup env
# if [[ $SHELL == *"fish"* ]]; then
#   fnm completions --shell fish
#   echo "fnm env --use-on-cd | source" > ~/.config/fish/conf.d/fnm.fish

#   fish -c "source ~/.config/fish/conf.d/fnm.fish"
#   fish
# elif [[ $SHELL == *"bash"* ]]; then
#   echo "SETUP FOR BASH"
#   echo 'eval "$(fnm env --use-on-cd)"' >> ~/.bashrc
#   fnm completions --shell bash

#   bash -c "source ~/.bashrc"
#   bash
# elif [[ $SHELL == *"zsh"* ]]; then
#   echo "SETUP FOR ZSH"
#   echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
#   fnm completions --shell zsh

#   zsh -c "source ~/.zshrc"
#   zsh
# else
#   fnm completions
# fi

# Use version
echo "USE VERSION"
fnm use --install-if-missing $(fnm ls | head -n 1)

# Enable Corepack (for Yarn and PNPM)
corepack enable
corepack prepare pnpm@latest --activate
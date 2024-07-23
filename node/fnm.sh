# Install fnm formula (if not installed)
if ! brew list | grep fnm; then
  brew install fnm
fi

eval "$(fnm env)"

# Install lts version
fnm install --lts --corepack-enabled

# Enable completions and setup env
if [[ $SHELL == *"fish"* ]]; then
    # Create the fnm.fish file with the specified content
  echo "fnm env --use-on-cd | source" > ~/.config/fish/conf.d/fnm.fish

  # Source the fnm.fish file in Fish shell
  fish -c "source ~/.config/fish/conf.d/fnm.fish"
  # fnm completions --shell fish
  fish
elif [[ $SHELL == *"bash"* ]]; then
  echo "SETUP FOR BASH"
  echo 'eval "$(fnm env --use-on-cd)"' >> ~/.bashrc
  fnm completions --shell bash

  bash -c "source ~/.bashrc"
  bash
elif [[ $SHELL == *"zsh"* ]]; then
  echo "SETUP FOR ZSH"
  echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
  fnm completions --shell zsh

  zsh -c "source ~/.zshrc"
  zsh
else
  fnm completions
fi

# Use version
echo "USE VERSION"
fnm use --install-if-missing $(fnm ls | head -n 1)

# Enable Corepack (for Yarn and PNPM)
corepack enable
corepack prepare pnpm@latest --activate
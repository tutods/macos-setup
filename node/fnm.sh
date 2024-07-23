# Install fnm formula (if not installed)
if ! brew list | grep fnm; then
  brew install fnm
fi

eval "$(fnm env)"

# Install lts version
fnm install --lts --corepack-enabled

# Enable completions and setup env
if [[ $SHELL == *"fish"* ]]; then
  fnm completions --shell fish
  touch ~/.config/fish/conf.d/fnm.fish
  echo "fnm env --use-on-cd | source" >> ~/.config/fish/conf.d/fnm.fish

  source ~/.config/fish/conf.d/fnm.fish
elif [[ $SHELL == *"bash"* ]]; then
  echo "SETUP FOR BASH"
  echo 'eval "$(fnm env --use-on-cd)"' >> ~/.bashrc

  source ~/.bashrc
  fnm completions --shell bash
elif [[ $SHELL == *"zsh"* ]]; then
  echo "SETUP FOR ZSH"
  echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc

  source ~/.zshrc
  fnm completions --shell zsh
else
  fnm completions
fi

# Use version
fnm use --install-if-missing --silent-if-unchanged $(fnm ls | head -n 1)

# Enable Corepack (for Yarn and PNPM)
corepack enable
corepack prepare pnpm@latest --activate
# Install fnm formula (if not installed)
if ! brew list | grep fnm; then
  brew install fnm
fi

# Add asdf to fish
touch ~/.config/fish/conf.d/fnm.fish
echo -e "fnm env --use-on-cd | source" >> ~/.config/fish/conf.d/fnm.fish

# Enable completions and setup env
fnm completions
fnm env

# Install lts version
fnm install --lts --corepack-enabled
fnm use -- --lts

# Enable Corepack (for Yarn and PNPM)
corepack enable
corepack prepare pnpm@latest --activate
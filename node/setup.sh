# Install asdf formula (if not installed)
if ! brew list | grep -q asdf; then
  brew install asdf
fi

# Add asdf to fish
echo -e "\nsource "(brew --prefix asdf)"/libexec/asdf.fish" >> ~/.config/fish/config.fish

# Add Node.js plugin
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

# Install lts version
asdf install nodejs latest
asdf global nodejs latest
asdf reshim nodejs

# Enable Corepack (for Yarn and PNPM)
corepack enable
corepack prepare pnpm@latest --activate

# Recreate shims for current Node.js version
asdf reshim nodejs
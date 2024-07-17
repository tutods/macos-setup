# Install asdf
git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.14.0

# Add asdf to fish
if grep -q "source ~/.asdf/asdf.fish" ~/.config/fish/config.fish; then
  echo "File already includes asdf"
else
  echo "File does not contain the specific line."
  
  mkdir -p ~/.config/fish/completions
  ln -s ~/.asdf/completions/asdf.fish ~/.config/fish/completions
  echo -e "\nsource ~/.asdf/asdf.fish" >> ~/.config/fish/config.fish
  source ~/.config/fish/config.fish
fi

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
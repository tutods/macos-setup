# Install asdf formula (if not installed)
echo "1) Install asdf"
brew ls --versions asdf || brew install asdf

# Add asdf to fish
echo "2) Add asdf to fish config"
echo -e "\nsource "(brew --prefix asdf)"/libexec/asdf.fish" >> ~/.config/fish/config.fish

# Add Node.js plugin
echo "3) Add Node.js plugin"
asdf plugin add nodejs https://github.com/asdf-vm/asdf-nodejs.git

# Install lts version
echo "4) Instal Node.js LTS version"
asdf install nodejs latest
asdf global nodejs latest

# Enable Corepack (for Yarn and PNPM)
echo "5) Enable Corepack and PNPM"
corepack enable
corepack prepare pnpm@latest --activate

# Recreate shims for current Node.js version
echo "6) Reshim Node.js"
asdf reshim nodejs
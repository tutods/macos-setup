# Check if fish is installed, if not install it
if ! brew list 2>/dev/null | grep -q fish; then
  brew install fish
fi

# Check if fuzzy search is installed, if not install it
if ! brew list 2>/dev/null | grep -q fzf; then
  brew install fzf
fi

# Check if zoxide is installed, if not install it
if ! brew list 2>/dev/null | grep -q zoxide; then
  brew install zoxide
fi

# Set as default shell
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

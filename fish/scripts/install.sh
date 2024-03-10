if ! brew list | grep -q fish; then
  brew install fish
fi

# Set as default shell
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

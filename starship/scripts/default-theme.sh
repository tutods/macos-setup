CONFIG_FILE="./configs/starship.toml"

# Check if starship is installed, if not install it
if ! brew list 2>/dev/null | grep -q starship; then
  brew install starship
fi

cp -f -r $CONFIG_FILE $HOME/.config/
# Check if starship is installed, if not install it
if ! brew list 2>/dev/null | grep -q starship; then
  brew install starship
fi

# TODO: setup shell
case $(basename $SHELL)
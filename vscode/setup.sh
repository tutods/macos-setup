DIR=$(dirname "$(readlink -f "$0")")
SETTINGS_FILE="$DIR/configs/settings.json"
EXTENSIONS_FILE="$DIR/configs/extensions.txt"

# Install VSCode (if not already installed)
if ! brew list | grep -q visual-studio-code; then
  brew install visual-studio-code
fi

# Replace config file
cp -f $SETTINGS_FILE ~/Library/Application Support/Code/User/settings.json

# Install extensions
# TODO: install extensions
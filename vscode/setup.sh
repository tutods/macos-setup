DIR=$(dirname "$(readlink -f "$0")")
SETTINGS_FILE="$DIR/configs/settings.json"
YAML_FILE="$DIR/list.yaml"

# Install VSCode (if not already installed)
if ! brew list | grep -q visual-studio-code; then
  brew install visual-studio-code
fi

# Replace config file
cp -f $SETTINGS_FILE ~/Library/Application Support/Code/User/settings.json

# Instlal extensions
EXTENSIONS=$(yq '.extensions[]' $YAML_FILE)
for extension in $EXTENSIONS; do
  code --install-extension $extension
done

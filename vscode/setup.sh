# echo "1) Install VSCode"
# if ! brew list | grep -q visual-studio-code; then
#   brew install visual-studio-code
# fi

# echo "2) Replace $(settings.json) file"
# cp -f ./configs/settings.json ~/Library/Application Support/Code/User/settings.json

echo "3) Install extensions"
DIR=$(dirname "$(readlink -f "$0")")
YAML_FILE="$DIR/list.yaml"
EXTENSIONS=$(yq '.extensions[]' $YAML_FILE)

for extension in $EXTENSIONS; do
  code --install-extension $extension
done

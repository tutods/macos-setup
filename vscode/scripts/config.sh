DIR=$(dirname "$(readlink -f "$0")")
SETTINGS_FILE="$DIR/settings.json"

# Replace config file
cp -f $SETTINGS_FILE $HOME/Library/Application\ Support/Code/User/settings.json
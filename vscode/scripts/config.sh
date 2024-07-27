DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
SETTINGS_FILE="$DIR/configs/settings.json"

# Replace config file
cat $SETTINGS_FILE > $HOME/Library/Application\ Support/Code/User/settings.json

~/Library/Application Support/Code/User/settings.json
DIR=$(dirname "$(readlink -f "$0")")
SETTINGS_FILE="$DIR/configs/settings.json"

# Replace config file
cp -f $SETTINGS_FILE ~/Library/Application Support/Code/User/settings.json
DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
SETTINGS_FILE="./configs/scripts.fish"
# Replace config file
cp -f $SETTINGS_FILE $HOME/Library/Application\ Support/Code/User/settings.json
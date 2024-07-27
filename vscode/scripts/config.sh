DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
SETTINGS_FILE="$DIR/configs/settings.json"

# Replace config file
DIR_PATH=$HOME/Library/Application\ Support/Code/User
FILE_PATH=$DIR_PATH/settings.json

# Check if the file exists
if [ ! -e "$FILE_PATH" ]; then
    if [ ! -d "$DIR_PATH" ]; then
        # Create the directory if it doesn't exist
        mkdir -p "$DIR_PATH"
    fi

    # Create the file if it doesn't exist
    touch "$FILE_PATH"
fi


cat $SETTINGS_FILE > $HOME/Library/Application\ Support/Code/User/settings.json
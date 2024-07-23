DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
CONFIG_FILE="$DIR/configs/config.fish"
KEY_BINDINGS_FILE="$DIR/configs/fish_user_key_bindings.fish"
FUNCTION_FILES="$DIR/configs/functions"
CONF_D_FILES="$DIR/configs/conf-d"

# Copy config files
cp -f $CONFIG_FILE ~/.config/fish/config.fish
cp -f $KEY_BINDINGS_FILE ~/.config/fish/functions/fish_user_key_bindings.fish
cp -r $FUNCTION_FILES ~/.config/fish/functions/
cp -r $CONF_D_FILES ~/.config/fish/conf.d/

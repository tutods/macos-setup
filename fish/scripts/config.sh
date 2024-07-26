DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
CONFIG_FILE="./configs/config.fish"
FUNCTION_FILES="./configs/functions"
CONF_D_FILES="./configs/conf.d"

# Copy config files
cp -f $CONFIG_FILE ~/.config/fish/config.fish
cp -r $FUNCTION_FILES ~/.config/fish/
cp -r $CONF_D_FILES ~/.config/fish/

DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
CONFIG_FILE="./configs/config.fish"
FUNCTION_FILES="./configs/functions"
CONF_D_FILES="./configs/conf.d"

# Copy config files
cp -f $CONFIG_FILE $HOME/.config/fish/config.fish
cp -f -r $FUNCTION_FILES $HOME/.config/fish/
cp -f -r $CONF_D_FILES $HOME/.config/fish/

fish -c "source $HOME/.config/fish/config.fish"
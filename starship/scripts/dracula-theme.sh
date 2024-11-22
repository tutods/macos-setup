DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
CONFIG_FILE="./configs/starship-dracula.toml"

# Copy config files
cp -f $CONFIG_FILE $HOME/.config/starship.toml

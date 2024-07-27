DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
OMF_FILE="$DIR/configs/omf.fish"

# Install OMF
# curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install

curl -sSf https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > install

eval "$(fish install --path=~/.local/share/omf --config=~/.config/omf)"

# eval "$(source $HOME/.config/fish/config.fish)"
# eval "$(source $HOME/.config/fish/conf.d/omf.fish)"

# Copy OMF config
# cp -f $OMF_FILE ~/.config/fish/conf.d
# eval "$(source $HOME/.config/fish/config.fish)"

# Install plugins
fish -c "omf install https://github.com/jhillyerd/plugin-git"
fish -c "omf install pisces"

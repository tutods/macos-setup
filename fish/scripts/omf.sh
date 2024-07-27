DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
OMF_FILE="$DIR/configs/omf.fish"

# Install OMF
# curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install

curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install > install
fish -c "fish install --path=~/.local/share/omf --config=~/.config/omf"

# eval "$(fish $HOME/.local/install --path=$HOME/.local/share/omf --config=$HOME/.config/omf)"
# rm $HOME/.local/install
# eval "$(source $OMF_PATH/init.fish)"

# Copy OMF config
# cp -f $OMF_FILE ~/.config/fish/conf.d
# eval "$(source $HOME/.config/fish/config.fish)"

# Install plugins
eval "$(omf install https://github.com/jhillyerd/plugin-git)"
eval "$(omf install pisces)"

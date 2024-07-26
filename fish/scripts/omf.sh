DIR=$(dirname "$(dirname "$(readlink -f "$0")")")
OMF_FILE="$DIR/configs/omf.fish"

# Install OMF
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

# Copy OMF config
cp -f $OMF_FILE ~/.config/fish/conf.d

# Install plugins
omf install git
omf install pisces

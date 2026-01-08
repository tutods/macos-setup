# Set fish as default shell
echo "↣ Set fish as default shell"
chsh -s /run/current-system/sw/bin/fish

# copy Hyper terminal config
echo "↣ Copy Hyper terminal config"
cp -r data/hyper.js $HOME/.hyper.js

sh ./install-vscode-extensions.sh

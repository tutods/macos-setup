echo "1) Install fish"
if ! brew list | grep -q fish; then
  brew install fish
fi

echo "2) Setup as default shell"
echo $(which fish) | sudo tee -a /etc/shells
chsh -s $(which fish)

echo "2) Install oh-my-fish"
curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish

echo "3) Add configurations"
cp -f ./configs/config.fish ~/.config/fish/config.fish
cp -f ./configs/omf.fish ~/.config/fish/conf.d/omf.fish
cp -f ./configs/fish_user_key_bindings.fish ~/.config/fish/functions/fish_user_key_bindings.fish

echo "4) Install plugins"
omf install git
omf install pisces
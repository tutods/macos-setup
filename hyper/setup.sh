DIR=$(dirname "$(readlink -f "$0")")
SETTINGS_FILE="$DIR/configs/hyper.js"

echo "1) Install hyper"
if ! brew list | grep -q hyper; then
  brew install --cask hyper
fi

echo "2) Copy configuration"
cp -f $SETTINGS_FILE ~/.hyper.js
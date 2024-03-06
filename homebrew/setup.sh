echo "1) Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install yq formula (if not installed)
echo "2) Install necessary formulas"
brew ls --versions yq || brew install yq

echo "3) Tap additional casks/formulas..."
brew tap homebrew/cask-versions
brew tap homebrew/cask-fonts

# File with Formulaes and Casks
DIR=$(dirname "$(readlink -f "$0")")
YAML_FILE="$DIR/list.yaml"

# Install formulaes
echo "4) Installing formulaes..."
FORMULAES=$(yq '.formulaes[]' $YAML_FILE)
brew install $FORMULAES

# Install casks
echo "5) Installing casks..."
APPS=$(yq '.casks[]' $YAML_FILE)
brew install --cask $APPS

# Remove yq installed before
echo "6) Cleanup"
brew remove yq
brew cleanup

echo "1) Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
echo "export PATH=/usr/local/bin:$PATH" >> ~/.bash_profile && source ~/.bash_profile


# Install yq formula (if not installed)
echo "2) Install necessary formulas"
brew ls --versions yq || brew ixnstall yq

# File with Formulaes and Casks
DIR=$(dirname "$(readlink -f "$0")")
YAML_FILE="$DIR/list.yaml"

# Install formulaes
echo "3) Installing formulaes..."
FORMULAES=$(yq '.formulaes[]' $YAML_FILE)
brew install $FORMULAES

# Install casks
echo "4) Installing casks..."
APPS=$(yq '.casks[]' $YAML_FILE)
brew install --cask $APPS

# Remove yq installed before
echo "5) Cleanup"
brew remove yq
brew cleanup

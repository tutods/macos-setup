echo "1) Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install yq formula (if not installed)
echo "2) Install necessary formulas"
brew ls --versions yq || brew install yq

echo "3) Tap additional casks/formulas..."
brew tap homebrew/cask-versions
brew tap homebrew/cask-fonts

# Install formulaes
echo "4) Installing formulaes..."
FORMULAES=$(yq '.formulaes[]' list.yaml)
brew install $FORMULAES

# Install casks
echo "5) Installing casks..."
APPS=$(yq '.casks[]' list.yaml)
brew install --cask $APPS

# Remove yq installed before
echo "6) Cleanup"
brew remove yq
brew cleanup

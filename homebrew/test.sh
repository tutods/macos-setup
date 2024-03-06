# Install yq formula (if not installed)
brew ls --versions yq || brew install yq

# Install casks
APPS=$(yq '.casks[]' install.yaml)
brew install --cask $APPS

# Install formulas
FORMULAS=$(yq '.formulas[]' install.yaml)
brew install $FORMULAS

# Remove yq installed before
# brew remove yq

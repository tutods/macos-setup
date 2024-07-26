# echo "1) Installing Homebrew..."
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

case $(basename $SHELL) in
    zsh)
        (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.zprofile && eval "$(/opt/homebrew/bin/brew shellenv)"
        ;;
    bash)
        (echo; echo 'eval "$(/opt/homebrew/bin/brew shellenv)"') >> $HOME/.bash_profile && eval "$(/opt/homebrew/bin/brew shellenv)"
        ;;
    *)
        echo "Unknown shell: $(basename $SHELL)"
        ;;
esac


# Check if it's everything ok
brew doctor

# Install yq formula (if not installed)
echo "2) Install necessary formulas"
brew ls --versions yq || brew install yq


# File with Formulaes and Casks
DIR=$(dirname "$(readlink -f "$0")")
echo $DIR
YAML_FILE="$DIR/list.yaml"

# Install formulaes
echo "3) Installing formulaes..."
FORMULAES=$(yq '.formulaes[]' $YAML_FILE)
brew tap shinokada/consize
brew install --force $FORMULAES

# Install casks
echo "4) Installing casks..."
APPS=$(yq '.casks[]' $YAML_FILE)
brew install --force --cask $APPS

# Remove yq installed before
echo "5) Cleanup"
brew remove yq
brew cleanup

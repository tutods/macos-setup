# copy Hyper terminal config
echo "↣ Copy Hyper terminal config"
cp -r data/hyper.js $HOME/.hyper.js

# Install remaining VSCode extensions
echo "↣ Installing remaining VSCode extensions"
code --install-extension chakrounanas.turbo-console-log 
code --install-extension wallabyjs.console-ninjarors
code --install-extension streetsidesoftware.code-spell-checker-portuguese
code --install-extension miguelsolorio.fluent-icons
code --install-extension maximus136.change-string-case
code --install-extension aliariff.auto-add-brackets
code --install-extension pflannery.vscode-versionlens
code --install-extension piotrpalarz.vscode-gitignore-generator
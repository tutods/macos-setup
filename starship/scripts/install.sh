# Check if starship is installed, if not install it
if ! brew list 2>/dev/null | grep -q starship; then
  brew install starship
fi

# TODO: setup shell
case $(basename $SHELL) in
  fish)
    echo "Fish shell detected!"
    echo "\n# Starship theme\nstarship init fish | source" >> $HOME/.config/fish/config.fish
    ;;
  bash)
    echo 'eval "$(starship init bash)"' >> $HOME/.bashrc
    ;;
  zsh)
    echo 'eval "$(starship init zsh)"' >> $HOME/.zshrc
    ;;
  *)
    echo "Unknown shell: $(basename $SHELL)"
    ;;
esac
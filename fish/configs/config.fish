if status is-interactive
  # Commands to run in interactive sessions can go here
end

# Startship theme
starship init fish | source

# Zoxide
zoxide init --cmd cd fish | source

# JetBrains Toolbox
export PATH="$HOME/.local/bin:$PATH"
#!/usr/bin/env bash
# macOS defaults that nix-darwin does not expose declaratively.
# Idempotent — `defaults write` is a no-op when the value is already set.
#
# Run from a nix-darwin activation script (root) or manually with sudo.
set -euo pipefail

####################
# SSD-specific tweaks
####################
# Disable hibernation (speeds up entering sleep mode)
sudo pmset -a hibernatemode 0

####################
# Audio
####################
# Increase sound quality for Bluetooth headphones/headsets
defaults write com.apple.BluetoothAudioAgent "Apple Bitpool Min (editable)" -int 40

####################
# Accessibility
####################
# Follow the keyboard focus while zoomed in
defaults write com.apple.universalaccess closeViewZoomFollowsFocus -bool true

####################
# Screen
####################
# Disable shadow in screenshots
defaults write com.apple.screencapture disable-shadow -bool true

####################
# Finder
####################
# Set sorting and sorting direction
defaults write com.apple.finder sortColumn -string "name"
defaults write com.apple.finder sortDirection -string "ascending"
# Automatically open a new Finder window when a volume is mounted
defaults write com.apple.frameworks.diskimages auto-open-ro-root -bool true
defaults write com.apple.frameworks.diskimages auto-open-rw-root -bool true

####################
# Network
####################
# Enable AirDrop over Ethernet and on unsupported Macs
defaults write com.apple.NetworkBrowser BrowseAllInterfaces -bool true

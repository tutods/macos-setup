#!/usr/bin/env bash

# Nix Darwin Configuration Manager
# Usage: ./nix.sh <configuration> [options]
# Example: ./nix.sh macbook
# Example: ./nix.sh macbook --build-only
# Example: ./nix.sh macbook --force

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_info()    { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error()   { echo -e "${RED}[ERROR]${NC} $1"; }

show_usage() {
  echo "Usage: $0 <configuration> [options]"
  echo ""
  echo "Configurations are defined in flake.nix (darwinConfigurations)."
  echo "Current configurations: macbook, work"
  echo ""
  echo "Options:"
  echo "  --build-only    Build configuration without applying"
  echo "  --force         Force rebuild even if no changes detected"
  echo "  --help, -h      Show this help message"
  echo ""
  echo "Examples:"
  echo "  $0 macbook"
  echo "  $0 macbook --build-only"
  echo "  $0 work --force"
  exit 0
}

check_directory() {
  if [[ ! -f "flake.nix" ]]; then
    print_error "Must be run from the .dotfiles directory (flake.nix not found)"
    exit 1
  fi
}

build_config() {
  local config="$1"
  local force="$2"

  print_info "Building configuration: $config"

  local build_cmd="nix --extra-experimental-features 'nix-command flakes' build \".#darwinConfigurations.$config.system\""
  [[ "$force" == "true" ]] && build_cmd="$build_cmd --rebuild"

  if eval "$build_cmd"; then
    print_success "Build successful"
  else
    print_error "Build failed"
    exit 1
  fi
}

apply_config() {
  local config="$1"
  local force="$2"

  print_info "Applying configuration: $config"

  local switch_cmd=("switch" "--flake" ".#$config")
  [[ "$force" == "true" ]] && switch_cmd+=("--rebuild")

  if command -v darwin-rebuild &>/dev/null; then
    print_info "Using local darwin-rebuild"
    if sudo darwin-rebuild "${switch_cmd[@]}"; then
      print_success "Configuration applied successfully"
    else
      print_error "Failed to apply configuration"
      exit 1
    fi
  else
    print_info "Using remote darwin-rebuild"
    if sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- "${switch_cmd[@]}"; then
      print_success "Configuration applied successfully"
    else
      print_error "Failed to apply configuration"
      exit 1
    fi
  fi
}

main() {
  if [[ $# -eq 0 ]]; then
    print_error "No configuration specified"
    show_usage
  fi

  local config="$1"
  local build_only=false
  local force=false

  case "$config" in
    --help|-h) show_usage ;;
  esac

  shift
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --build-only) build_only=true ;;
      --force)      force=true ;;
      --help|-h)    show_usage ;;
      *) print_error "Unknown option: $1"; show_usage ;;
    esac
    shift
  done

  check_directory

  print_info "Configuration: $config"

  if [[ "$build_only" == "true" ]]; then
    build_config "$config" "$force"
    print_success "Build complete! Run without --build-only to apply."
  else
    apply_config "$config" "$force"
    print_success "Done! Run 'brew doctor' if you encounter Homebrew issues."
  fi
}

main "$@"

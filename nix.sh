#!/usr/bin/env bash

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

print_info()    { echo -e "  ${BLUE}➜${NC}  $1"; }
print_success() { echo -e "  ${GREEN}✔${NC}  $1"; }
print_warning() { echo -e "  ${YELLOW}⚠${NC}  $1"; }
print_error()   { echo -e "  ${RED}✖${NC}  $1"; }
print_step()    { echo -e "\n${BOLD}[$1]${NC}"; }

print_banner() {
  echo -e "${BOLD}${BLUE}"
  echo '  ╔══════════════════════════════════╗'
  echo '  ║       nix · darwin · deploy     ║'
  echo '  ╚══════════════════════════════════╝'
  echo -e "${NC}"
}

show_usage() {
  print_banner
  echo -e "${BOLD}Usage:${NC} $0 <configuration> [options]"
  echo ""
  echo -e "${BOLD}Configurations${NC} ${DIM}(defined in flake.nix)${NC}"
  echo "  macbook      Personal MacBook"
  echo "  work         Work laptop"
  echo ""
  echo -e "${BOLD}Options${NC}"
  echo "  --build-only    Build without applying"
  echo "  --force         Force rebuild even if no changes"
  echo "  --help, -h      Show this help message"
  echo ""
  echo -e "${BOLD}Examples${NC}"
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

setup_private_git() {
  local private_file="$HOME/.config/git/private"

  if [[ -f "$private_file" ]]; then
    return 0
  fi

  print_warning "Private git config not found at $private_file"
  echo -e "     ${YELLOW}Git user.name and user.email are required.${NC}"
  echo -e "     ${YELLOW}See docs/private-git-config.md for details.${NC}"
  echo ""

  local name email
  read -rp "  Enter your git user.name: " name
  read -rp "  Enter your git user.email: " email

  if [[ -z "$name" || -z "$email" ]]; then
    print_error "Both name and email are required. Skipping private git config."
    return 1
  fi

  mkdir -p "$(dirname "$private_file")"
  git config --file "$private_file" user.name "$name"
  git config --file "$private_file" user.email "$email"

  print_success "Private git config created at $private_file"
}

build_config() {
  local config="$1"
  local force="$2"

  print_step "Building"
  print_info "Configuration: $config"

  local build_cmd=(nix --extra-experimental-features 'nix-command flakes' build ".#darwinConfigurations.$config.system")
  [[ "$force" == "true" ]] && build_cmd+=(--rebuild)

  if "${build_cmd[@]}"; then
    print_success "Build successful"
  else
    print_error "Build failed"
    exit 1
  fi
}

apply_config() {
  local config="$1"
  local force="$2"

  print_step "Applying"
  print_info "Configuration: $config"

  local switch_cmd=(switch --flake ".#$config")
  [[ "$force" == "true" ]] && switch_cmd+=(--rebuild)

  local rebuild_cmd
  if command -v darwin-rebuild &>/dev/null; then
    print_info "Using local darwin-rebuild"
    rebuild_cmd=(sudo darwin-rebuild "${switch_cmd[@]}")
  else
    print_info "Using remote darwin-rebuild"
    rebuild_cmd=(sudo nix --extra-experimental-features 'nix-command flakes' run nix-darwin/master#darwin-rebuild -- "${switch_cmd[@]}")
  fi

  if "${rebuild_cmd[@]}"; then
    print_success "Configuration applied"
  else
    print_error "Failed to apply configuration"
    exit 1
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
  setup_private_git

  print_banner
  print_info "Configuration: ${BOLD}$config${NC}"

  if [[ "$build_only" == "true" ]]; then
    build_config "$config" "$force"
    echo ""
    print_success "Build complete! Run without --build-only to apply."
  else
    apply_config "$config" "$force"
    echo ""
    print_success "Done! Run ${BOLD}brew doctor${NC} if you encounter Homebrew issues."
  fi
}

main "$@"